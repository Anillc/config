{ pkgs, config, lib, ... }: with lib; let
    zones = {
        "an.dn42" = import ./zones/an.dn42.nix pkgs;
        "an.neo"  = import ./zones/an.neo.nix  pkgs;
        "96/27.167.22.172.in-addr.arpa" = import ./zones/167.22.172.in-addr.arpa.nix pkgs;
        "e.c.0.d.1.c.3.8.9.c.d.f.ip6.arpa" = import ./zones/e.c.0.d.1.c.3.8.9.c.d.f.ip6.arpa.nix pkgs;
        "0.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa" = import ./zones/0.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa.nix pkgs;
        "f.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa" = import ./zones/f.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa.nix pkgs;
    };
in {
    config = mkIf config.bgp.enable {
        net = {
            addresses = [
                { address = "${config.meta.v4}/32";  interface = "dns"; }
                { address = "${config.meta.v6}/128"; interface = "dns"; }
            ];
            routes = [
                { dst = "172.22.167.126/32";      interface = "dns"; proto = 114; table = 114; }
                { dst = "fdc9:83c1:d0ce::ff/128"; interface = "dns"; proto = 114; table = 114; }
            ];
        };
        systemd.services.net.partOf = [ "container@dns.service" ];
        systemd.services."container@dns".before = [ "net.service" ];
        containers.dns = {
            autoStart = true;
            privateNetwork = true;
            extraVeths.dns = {};
            config = { ... }: {
                imports = [ ../networking/def ];
                nixpkgs.overlays = [(self: super: {
                    inherit (pkgs) dns;
                })];
                firewall.publicTCPPorts = [ 53 ];
                firewall.publicUDPPorts = [ 53 ];
                networking.interfaces.dns.ipv4.addresses = [{ address = "172.22.167.126"; prefixLength = 32; }];
                networking.interfaces.dns.ipv6.addresses = [{ address = "fdc9:83c1:d0ce::ff"; prefixLength = 128; }];
                networking.defaultGateway  = { address = config.meta.v4; interface = "dns"; };
                networking.defaultGateway6 = { address = config.meta.v6; interface = "dns"; };
                services.bind = {
                    enable = true;
                    configFile = pkgs.writeText "named.conf" ''
                        options {
                            directory "/run/named";
                            pid-file "/run/named/named.pid";
                            listen-on { any; };
                            listen-on-v6 { any; };
                            allow-query { any; };
                            recursion no;
                        };
                        ${builtins.foldl' (acc: x: ''
                            ${acc}
                            zone "${x}" {
                                type master;
                                file "${zones.${x}}";
                            };
                        '') "" (builtins.attrNames zones)}
                    '';
                    inherit zones;
                };
            };
        };
    };
}