rec {
    meta = {
        id = 3;
        name = "sum";
        wg-public-key = "0D6pTWyy9lO/rw2xSOtNjnayPLEMyrg5eP2FUiHDlUI=";
        syncthingId = "EKZAAU6-E2DNAKJ-XQY7XJQ-JFYFSTT-LWYNIX3-4V2YSMY-TO7QMT4-NIA7GAV";
    };
    configuration = { config, pkgs, lib, inputs, ... }: let
        pkgs-meilisearch = import inputs.nixpkgs-meilisearch { inherit (pkgs) system; };
    in {
        cfg.meta = meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
                vaultwarden = {};
                meilisearch = {};
            };
        };
        services.meilisearch = {
            enable = true;
            package = pkgs-meilisearch.meilisearch;
            masterKeyEnvironmentFile = config.sops.secrets.meilisearch.path;
        };
        services.vaultwarden = {
            enable = true;
            environmentFile = config.sops.secrets.vaultwarden.path;
            config = {
                DOMAIN = "https://vw.anil.lc";
                SIGNUPS_ALLOWED = false;
            };
        };
        security.acme.certs = lib.mkMerge [ (lib.genAttrs [
            "search.koishi.chat" "search.cordis.moe"
        ] (_: { email = "admin@forum.koishi.chat"; })) ];
        cfg.firewall.publicTCPPorts = [ 80 443 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            clientMaxBodySize = "0";
            virtualHosts = {
                "rsshub.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://cola:8082";
                    };
                };
                "search.koishi.chat" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:7700";
                    };
                };
                "search.cordis.moe" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:7700";
                    };
                };
                "vw.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8000";
                    };
                };
            };
        };
    };
}