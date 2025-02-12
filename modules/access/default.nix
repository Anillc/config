{ config, pkgs, lib, inputs, ... }: let
  cfg = config.cfg.access;
  inherit (import inputs.nixpkgs-new { inherit (pkgs) system; }) sing-box;
  sing-box-config = pkgs.callPackage ./sing-config.nix {};
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
    forwards = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options.ip = lib.mkOption {
          type = lib.types.str;
          description = "ip";
        };
        options.from-port = lib.mkOption {
          type = lib.types.port;
          description = "from port";
        };
        options.to-port = lib.mkOption {
          type = lib.types.port;
          description = "to port";
        };
      });
      description = "forwards";
      default = [];
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

    systemd.services."container@access".after = [ "sing-box.service" ];
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
        networking.useNetworkd = true;
        systemd.network.networks.access = {
          matchConfig.Name = "access";
          networkConfig = {
            Address = "${cfg.ip}/32";
            ConfigureWithoutCarrier = "yes";
          };
          routes = [ { routeConfig = {
            Gateway = config.cfg.meta.v4;
            GatewayOnLink = "yes";
          }; } ];
        };
        systemd.network.networks.${cfg.interface} = {
          matchConfig.Name = cfg.interface;
          networkConfig = {
            Address = "192.168.1.1/24";
            ConfigureWithoutCarrier = "yes";
          };
        };
        systemd.network.networks.proxy = {
          matchConfig.Name = "lo";
          routes = [ { routeConfig = {
            Destination = "0.0.0.0/0";
            Type = "local";
            Table = 233;
          }; } ];
          # TODO:
          extraConfig = ''
            [RoutingPolicyRule]
            FirewallMark=233
            Table=233
          '';
        };

        cfg.firewall.enableSourceFilter = false;
        cfg.firewall.publicTCPPorts = [ 53 9090 ];
        cfg.firewall.publicUDPPorts = [ 53 ];
        cfg.firewall.extraInputRules = ''
          # dhcp
          ip saddr 0.0.0.0/32 accept
          meta mark 233 accept
        '';
        cfg.firewall.extraPreroutingFilterRules = lib.mkAfter ''
          # proxy dns
          ip daddr $RESERVED_IP udp dport != 53 return
          ip daddr $RESERVED_IP tcp dport != 53 return
          # masquerade in extraPostroutingRules
          ${lib.concatMapStrings (forward: ''
            iifname "access" tcp sport ${toString forward.to-port} return
            iifname "access" udp sport ${toString forward.to-port} return
          '') cfg.forwards}
          ip protocol { tcp, udp } meta mark set 233 tproxy ip to 127.0.0.1:9898
        '';
        cfg.firewall.extraOutputRouteRules = lib.mkAfter ''
          # proxy dns
          ip daddr $RESERVED_IP udp dport != 53 return
          ip daddr $RESERVED_IP tcp dport != 53 return
          ip protocol { tcp, udp } meta mark set 233
        '';
        cfg.firewall.extraPreroutingRules = lib.concatMapStrings (forward: ''
          iifname "access" tcp dport ${toString forward.from-port} dnat ip to ${forward.ip}:${toString forward.to-port}
          iifname "access" udp dport ${toString forward.from-port} dnat ip to ${forward.ip}:${toString forward.to-port}
        '') cfg.forwards;
        cfg.firewall.extraPostroutingFilterRules = ''
          meta iifname "${cfg.interface}" oifname "access" meta mark set 0x114
        '';

        boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv4.conf.all.rp_filter" = 0;
        };

        networking.nameservers = [ "10.11.1.2" ];
        networking.useHostResolvConf = false;
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

        # ctos -s 'xxx' gen | jq -s '[.[0].outbounds[] | select(.type | contains("vmess", "shadowsocks", "urltest"))]'
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
            cat ${sing-box-config} $CREDENTIALS_DIRECTORY/ap | jq -s -r '
              .[0].outbounds += .[1] | .[0]
            ' > /etc/sing-box/config.json
          '';
        };

        environment.systemPackages = [ pkgs.mtr pkgs.dig pkgs.tcpdump ];
      };
    };

  };
}