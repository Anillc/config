rec {
    meta = {
        id = 5;
        name = "lux";
        wg-public-key = "5gF5o4Cn5/J8t8aEGdCK/x5wKTLC8qpywNbqOc4J530=";
        syncthingId = "PMTKO4J-OWTTMXH-JNIVUHV-R4PZQMQ-WMJPXGT-B27RWEY-FPZ2DAQ-AP3LLQF";
    };
    configuration = { config, pkgs, lib, inputs, ... }: let
        pkgs-meilisearch = import inputs.nixpkgs-meilisearch { inherit (pkgs) system; };
    in {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./firefish.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
                meilisearch = {};
            };
        };
        services.calibre-web = {
            enable = true;
            listen.ip = "127.0.0.1";
            options = {
                enableBookUploading = true;
                enableBookConversion = true;
            };
        };
        services.meilisearch = {
            enable = true;
            package = pkgs-meilisearch.meilisearch;
            masterKeyEnvironmentFile = config.sops.secrets.meilisearch.path;
        };
        security.acme.certs."search.koishi.chat" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "admin@forum.koishi.chat";
        };
        security.acme.certs."search.cordis.moe" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "admin@forum.koishi.chat";
        };
        security.acme.certs."c.ff.ci" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "void@anil.lc";
        };
        security.acme.certs."sso.anil.lc" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "void@anil.lc";
        };
        security.acme.certs."ff.ci" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "void@anil.lc";
        };
        firewall.publicTCPPorts = [ 80 443 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "c.ff.ci" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8083";
                    };
                };
                "sso.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://10.11.1.8:8080";
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
                "ff.ci" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://10.11.1.9:3000";
                    };
                };
            };
        };
    };
}