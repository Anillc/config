{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.dns;
in {
    config = mkIf cfg.enable {
        bgp.extraBirdConfig = ''
            protocol static {
                route 10.11.1.2/32 via "dnsmasq";
                ipv4 {
                    table igp_v4;
                };
            }
            protocol static {
                route fd11:1::2/128 via "dnsmasq";
                ipv6 {
                    table igp_v6;
                };
            }
        '';
        firewall.extraPostroutingFilterRules = ''
            meta iifname dnsmasq meta oifname "en*" meta mark set 0x114
        '';
        containers.dnsmasq = {
            autoStart = true;
            privateNetwork = true;
            extraVeths.dnsmasq = {};
            config = { ... }: {
                imports = [ ../networking/def/firewall.nix ];
                system.stateVersion = "22.05";
                documentation.enable = false;
                firewall.publicTCPPorts = [ 53 ];
                firewall.publicUDPPorts = [ 53 ];
                networking.interfaces.dnsmasq.ipv4.addresses = [{ address = "10.11.1.2"; prefixLength = 32;  }];
                networking.interfaces.dnsmasq.ipv6.addresses = [{ address = "fd11:1::2"; prefixLength = 128; }];
                networking.defaultGateway  = { address = config.meta.v4; interface = "dnsmasq"; };
                networking.defaultGateway6 = { address = config.meta.v6; interface = "dnsmasq"; };
                services.dnsmasq = {
                    enable = true;
                    resolveLocalQueries = false;
                    settings.server = [
                            "/a/10.11.1.1"

                            "114.114.114.114"
                            "223.5.5.5"
                            "8.8.8.8"
                            "8.8.4.4"
                    ];
                };
            };
        };
    };
}