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
                settings.server = [
                    "/a/10.11.1.2"

                    "114.114.114.114"
                    "223.5.5.5"
                    "8.8.8.8"
                    "8.8.4.4"
                ];
            };
        })
    ];
}