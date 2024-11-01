rec {
    meta = {
        id = 3;
        name = "hk";
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
        syncthingId = "2QRC73T-DM7XGW5-NLACT6B-ODINVTO-BNSHQGF-52IAOSR-OAKHZZK-EAPDIAL";
    };
    configuration = { config, pkgs, lib, ... }: {
        cfg.meta = meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./ca
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.vaultwarden = {};
            secrets.ca-key = {};
            secrets.bot-proxy-auth = {
                owner = "nginx";
                group = "nginx";
            };
        };
        services.vaultwarden = {
            enable = true;
            environmentFile = config.sops.secrets.vaultwarden.path;
            config = {
                DOMAIN = "https://vw.anil.lc";
                SIGNUPS_ALLOWED = false;
            };
        };
        services.ntfy-sh = {
            enable = true;
            settings = {
                behind-proxy = true;
                listen-http = ":8080";
                base-url = "https://ntfy.anil.lc";
                auth-default-access = "deny-all";
            };
        };
        cfg.sync = [
            "/var/lib/bitwarden_rs"
        ];
        cfg.firewall.publicTCPPorts = [ 80 443 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            virtualHosts = {
                "vw.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8000";
                    };
                };
                "ntfy.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
            };
        };
    };
}