rec {
    meta = {
        id = 3;
        name = "hk";
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
        syncthingId = "2QRC73T-DM7XGW5-NLACT6B-ODINVTO-BNSHQGF-52IAOSR-OAKHZZK-EAPDIAL";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.vaultwarden = {};
            secrets.bot-proxy-auth = {
                owner = "nginx";
                group = "nginx";
            };
        };
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "38008";
                address = "2406:4440::1";
            };
            peers.aperix = { # APERIX
                asn = "38008";
                address = "2406:4440::100";
            };
        };
        services.vaultwarden = {
            enable = true;
            environmentFile = config.sops.secrets.vaultwarden.path;
            config = {
                DOMAIN = "https://vw.anillc.cn";
                SIGNUPS_ALLOWED = false;
            };
        };
        sync = [
            "/var/lib/bitwarden_rs"
        ];
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            virtualHosts = {
                "vw.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8000";
                    };
                };
                "bot.anillc.cn" = {
                    basicAuthFile = config.sops.secrets.bot-proxy-auth.path;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://bot.a:8056";
                    };
                };
                "yt.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://sh.a";
                    };
                };
            };
        };
    };
}