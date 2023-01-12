{ config, lib, ... }:

with builtins;
with lib;

let
    cfg = config.dns;
in {
    options.dns.enable = mkOption {
        type = types.bool;
        description = "dns";
        default = true;
    };
    imports = [
        ./knot.nix
        ./dnsmasq.nix
    ];
    config = mkMerge [
        {
            networking.resolvconf.extraConfig = ''
                search_domains='a'
            '';
        }
        (mkIf cfg.enable {
            networking.nameservers = [ "10.11.1.2" ];
        })
        (mkIf (!cfg.enable) {
            networking.nameservers = [ "127.0.0.1" ];
            services.dnsmasq = {
                enable = true;
                resolveLocalQueries = false;
                servers = [
                    "/a/10.11.1.2"

                    "/mycard.moe/10.11.1.2"
                    "/momobako.com/10.11.1.2"
                    "/yuzurisa.com/10.11.1.2"
                    "/moecube.com/10.11.1.2"
                    "/ygobbs.com/10.11.1.2"
                    "/newwise.com/10.11.1.2"
                    "/my-card.in/10.11.1.2"

                    "114.114.114.114"
                    "223.5.5.5"
                    "8.8.8.8"
                    "8.8.4.4"
                ];
            };
        })
    ];
}