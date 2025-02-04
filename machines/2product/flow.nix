{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    cfg.firewall.extraPostroutingFilterRules = ''
        meta iifname "flow" meta mark set 0x114
    '';
    services.bird2.config = ''
        protocol static {
            route 10.11.1.4/32 via "flow";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    # for masquerade
    systemd.network.networks = listToAttrs (map (x: nameValuePair "i${x.name}" {
        address = [ "${config.cfg.meta.v4}/32" "${config.cfg.meta.v6}/128" ];
    }) config.cfg.wgi);
    containers.flow = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.flow = {};
        interfaces = [ "ens19" ];
        config = { ... }: {
            imports = [ ../../modules/networking/def/firewall.nix ];
            system.stateVersion = "22.05";
            documentation.enable = false;
            networking.firewall.enable = false;
            networking.interfaces.flow.ipv4.addresses = [{ address = "10.11.1.4"; prefixLength = 32; }];
            networking.interfaces.ens19.ipv4.addresses = [{ address = "192.168.1.1"; prefixLength = 24; }];
            networking.defaultGateway  = { address = config.cfg.meta.v4; interface = "flow"; };
            boot.kernel.sysctl = {
                "net.ipv4.ip_forward" = 1;
                "net.ipv4.conf.all.rp_filter" = 0;
            };
            cfg.firewall.enableSourceFilter = false;
            cfg.firewall.extraPostroutingFilterRules = ''
                meta iifname "ens19" meta oifname "flow" meta mark set 0x114
            '';
            # dhcp
            cfg.firewall.extraInputRules = "ip saddr 0.0.0.0/32 accept";

            cfg.firewall.publicTCPPorts = [ 53 ];
            cfg.firewall.publicUDPPorts = [ 53 ];
            networking.nameservers = mkForce [ "127.0.0.1" ];
            networking.resolvconf.useLocalResolver = false;
            services.dnsmasq = {
                enable = true;
                resolveLocalQueries = false;
                settings = {
                    server = [ "/a/10.11.1.1" "8.8.8.8" ];
                    interface = "ens19";
                    bogus-priv = true;
                    dhcp-range = "192.168.1.2,192.168.1.254,24h";
                    dhcp-option = [
                        "option:dns-server,192.168.1.1"
                        "option:domain-search,a"
                    ];
                };
            };

            environment.systemPackages = [ pkgs.mtr pkgs.dig pkgs.tcpdump ];
        };
    };
}