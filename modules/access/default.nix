{ config, pkgs, lib, inputs, ... }: let
  cfg = config.cfg.access;
  inherit (import inputs.nixpkgs-new { inherit (pkgs) system; }) sing-box;
  sing-box-config = pkgs.writeText "config.json" (lib.generators.toJSON {} {
    route.rule_set = [
      {
        type = "local";
        tag = "s_geoip-cn";
        format = "binary";
        path = "${pkgs.sing-geoip}/share/sing-box/rule-set/geoip-cn.srs";
      }
      {
        type = "local";
        tag = "s_geosite-cn";
        format = "binary";
        path = "${pkgs.sing-geosite}/share/sing-box/rule-set/geosite-cn.srs";
      }
    ];
    experimental.clash_api = {
      external_controller = "0.0.0.0:9090";
      external_ui = pkgs.nur.repos.linyinfeng.yacd;
    };

    dns = {
      servers = [
        { tag = "s_google"; address = "tls://8.8.8.8"; }
        { tag = "s_local"; address = "10.11.1.2"; detour = "s_direct"; }
      ];
      rules = [
        { domain_suffix = ".a"; server = "s_local"; }
        { outbound = "s_select"; server = "s_google"; }
        { outbound = "any"; server = "s_local"; }
      ];
    };

    inbounds = [
      {
        type = "tun";
        tag = "s_tun-in";
        address = [ "10.114.0.1/30" ];
        auto_route = true;
      }
    ];

    outbounds = [
      { type = "direct"; tag = "s_direct"; }
      {
        type = "selector";
        tag = "s_select";
        default = "select";
        outbounds = [ "select" "s_direct" ];
      }
    ];

    route = {
      rules = [
        { action = "sniff"; }
        { action =  "hijack-dns"; protocol = "dns"; }
        { rule_set = "s_geoip-cn"; outbound = "s_direct"; }
        { rule_set = "s_geosite-cn"; outbound = "s_direct"; }
        { ip_is_private = true; outbound = "s_direct"; }
      ];
      final = "s_select";
      auto_detect_interface = true;
    };
  });
in {
  options.cfg.access = {
    enable = lib.mkEnableOption "access";
    interface = lib.mkOption {
      type = lib.types.str;
      description = "interface to be moved";
    };
    ip = lib.mkOption {
      type = lib.types.str;
      description = "ip address of container";
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets.sing-box-secret = {
      sopsFile = ./sing-box-secret;
      format = "binary";
    };
    cfg.firewall.extraPostroutingFilterRules = ''
        meta iifname "access" meta mark set 0x114
    '';
    services.bird2.config = ''
      protocol static {
        route ${cfg.ip}/32 via "access";
        ipv4 {
            table igp_v4;
        };
      }
    '';
    # for masquerade
    systemd.network.networks = lib.mergeAttrsList (lib.map ({ name, ... }: {
      "i${name}" = {
        address = [ "${config.cfg.meta.v4}/32" "${config.cfg.meta.v6}/128" ];
      };
    }) config.cfg.wgi);
    containers.access = {
      autoStart = true;
      privateNetwork = true;
      bindMounts."/run/secrets" = {};
      enableTun = true;
      extraVeths.access = {};
      interfaces = [ cfg.interface ];
      config = {
        imports = [ ../networking/def/firewall.nix ];

        system.stateVersion = "22.05";
        documentation.enable = false;

        networking.firewall.enable = false;
        networking.interfaces.access.ipv4.addresses = [{ address = cfg.ip; prefixLength = 32; }];
        networking.interfaces.${cfg.interface}.ipv4.addresses = [{ address = "192.168.1.1"; prefixLength = 24; }];
        networking.defaultGateway  = { address = config.cfg.meta.v4; interface = "access"; };
        cfg.firewall.extraInputRules = ''
          # dhcp
          ip saddr 0.0.0.0/32 accept
          meta iifname "tun0" accept
        '';
        cfg.firewall.publicTCPPorts = [ 53 9090 ];
        cfg.firewall.publicUDPPorts = [ 53 ];
        cfg.firewall.enableSourceFilter = false;
        # masquerade packets that aren't proxied by sing-box
        cfg.firewall.extraPostroutingFilterRules = ''
            meta iifname "${cfg.interface}" oifname "access" meta mark set 0x114
        '';
        boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv4.conf.all.rp_filter" = 0;
        };

        networking.resolvconf.useLocalResolver = false;
        services.dnsmasq = {
          enable = true;
          resolveLocalQueries = false;
          settings = {
            inherit (cfg) interface;
            port = 0;
            bogus-priv = true;
            dhcp-range = "192.168.1.2,192.168.1.254,24h";
            dhcp-option = [
              "option:dns-server,10.11.1.2"
              "option:domain-search,a"
            ];
          };
        };

        services.sing-box = {
          enable = true;
          package = sing-box;
        };
        systemd.services.sing-box = {
          serviceConfig.LoadCredential = "ap:${config.sops.secrets.sing-box-secret.path}";
          path = with pkgs; [ jq ];
          # TODO: /run/sing-box/config.json after 24.11
          preStart = lib.mkForce ''
            umask 0077
            mkdir -p /etc/sing-box
            cat ${sing-box-config} $CREDENTIALS_DIRECTORY/ap | jq -s -r '.[0].outbounds += .[1].outbounds | .[0]' > /etc/sing-box/config.json
          '';
        };

        environment.systemPackages = [ pkgs.mtr pkgs.dig pkgs.tcpdump ];
      };
    };

  };
}