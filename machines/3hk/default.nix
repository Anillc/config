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
        security.acme.certs."m.anil.lc" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "void@anil.lc";
        };
        firewall.publicTCPPorts = [ 80 443 ];
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
                "m.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/".extraConfig = "return 404;";
                    locations."/_matrix".proxyPass = "http://cola.a:8008";
                    locations."/_synapse/client".proxyPass = "http://cola.a:8008";
                    locations."= /.well-known/matrix/server".extraConfig = ''
                        return 200 '{ "m.server": "m.anil.lc:443" }';
                    '';
                    locations."= /.well-known/matrix/client".extraConfig = ''
                        return 200 '{ "m.homeserver": { "base_url": "https://m.anil.lc" } }';
                    '';
                };
            };
        };
    };
}