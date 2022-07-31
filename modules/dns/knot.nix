{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    cfg = config.dns;
in {
    config = mkIf cfg.enable {
        bgp.extraBirdConfig = ''
            protocol static {
                route 10.11.1.1/32 via "dns";
                ipv4 {
                    table igp_v4;
                };
            }
            protocol static {
                route fd11:1::1/128 via "dns";
                ipv6 {
                    table igp_v6;
                };
            }
        '';
        containers.dns = {
            autoStart = true;
            privateNetwork = true;
            extraVeths.dns = {};
            config = { ... }: {
                imports = [ ../networking/def/firewall.nix ];
                system.stateVersion = "22.05";
                documentation.enable = false;
                firewall.publicTCPPorts = [ 53 ];
                firewall.publicUDPPorts = [ 53 ];
                networking.interfaces.dns.ipv4.addresses = [{ address = "10.11.1.1"; prefixLength = 32;  }];
                networking.interfaces.dns.ipv6.addresses = [{ address = "fd11:1::1"; prefixLength = 128; }];
                networking.defaultGateway  = { address = config.meta.v4; interface = "dns"; };
                networking.defaultGateway6 = { address = config.meta.v6; interface = "dns"; };
                services.knot = {
                    enable = true;
                    extraConfig = ''
                        server:
                            listen: 0.0.0.0@53
                            listen: ::@53
                        log:
                          - target: syslog
                            any: info
                        zone:
                          - domain: a
                            file: ${pkgs.callPackage ./a.zone.nix { inherit inputs; }}
                    '';
                };
            };
        };
    };
}