{ pkgs, config, lib, ... }: with lib; let
    cfg = config.dns;
    zones = {
        "an.dn42" = import ./zones/an.dn42.nix pkgs;
        "an.neo"  = import ./zones/an.neo.nix  pkgs;
        "96/27.167.22.172.in-addr.arpa" = import ./zones/167.22.172.in-addr.arpa.nix pkgs;
        "e.c.0.d.1.c.3.8.9.c.d.f.ip6.arpa" = import ./zones/e.c.0.d.1.c.3.8.9.c.d.f.ip6.arpa.nix pkgs;
        "0.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa" = import ./zones/0.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa.nix pkgs;
        "f.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa" = import ./zones/f.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa.nix pkgs;
    };
in {
    options.dns = {
        enable = mkEnableOption "enable dns service";
    };
    config = mkIf cfg.enable {
        networking.resolvconf.useLocalResolver = false;
        firewall.publicTCPPorts = [ 53 ];
        firewall.publicUDPPorts = [ 53 ];
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
}