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
                "ha.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "https://ha.a";
                    };
                };
                "vw.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8000";
                    };
                };
                "bot.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://bot.a:8056";
                        basicAuthFile = config.sops.secrets.bot-proxy-auth.path;
                    };
                    locations."/github" = {
                        proxyWebsockets = true;
                        proxyPass = "http://bot.a:8056";
                    };
                };
                "ff.ci" = {
                    locations."/s/" = {
                        proxyPass = "http://bot.a:8056";
                    };
                };
                "matrix.anillc.cn" = {
                    locations."/".extraConfig = "return 404;";
                    locations."/_matrix".proxyPass = "http://cola.a:8008";
                    locations."/_synapse/client".proxyPass = "http://cola.a:8008";
                    locations."= /.well-known/matrix/server".extraConfig = ''
                        return 200 '{ "m.server": "matrix.anillc.cn:443" }';
                    '';
                    locations."= /.well-known/matrix/client".extraConfig = ''
                        return 200 '{ "m.homeserver": { "base_url": "https://matrix.anillc.cn" } }';
                    '';
                };
            };
        };
    };
}