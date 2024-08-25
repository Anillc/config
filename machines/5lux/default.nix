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
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
                meilisearch = {};
                miniflux = {};
                rsshub = {};
                minio = {
                    owner = "minio";
                    group = "minio";
                };
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
        systemd.services.minio.environment = {
            MINIO_SERVER_URL = "https://s3.anil.lc";
            MINIO_BROWSER_REDIRECT_URL = "https://minio.anil.lc";
        };
        services.minio = {
            enable = true;
            dataDir = [ "/data/minio" ];
            listenAddress = ":9000";
            consoleAddress = ":9001";
            rootCredentialsFile = config.sops.secrets.minio.path;
            region = "lu-1";
        };
        services.miniflux = {
            enable = true;
            adminCredentialsFile = config.sops.secrets.miniflux.path;
            config.LISTEN_ADDR = "127.0.0.1:8081";
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.rsshub = {
                image = "docker.io/diygod/rsshub:chromium-bundled";
                ports = [ "8082:1200" ];
                environmentFiles = [ config.sops.secrets.rsshub.path ];
            };
        };
        services.jellyfin = {
            enable = true;
            dataDir = "/data/jellyfin";
        };
        security.acme.certs = lib.mkMerge [ (lib.genAttrs [
            "search.koishi.chat" "search.cordis.moe"
        ] (_: {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "admin@forum.koishi.chat";
        })) (lib.genAttrs [
            "c.ff.ci" "sso.anil.lc" "rsshub.anil.lc"
            "s3.anil.lc" "minio.anil.lc" "rss.anil.lc"
            "jellyfin.anil.lc"
        ] (_: {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "void@anil.lc";
        })) ];
        firewall.publicTCPPorts = [ 80 443 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            clientMaxBodySize = "0";
            virtualHosts = {
                "c.ff.ci" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8083";
                    };
                };
                "s3.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:9000";
                    };
                };
                "minio.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:9001";
                        extraConfig = ''
                            proxy_set_header X-NginX-Proxy true;
                        '';
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
                "rss.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8081";
                    };
                };
                "rsshub.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8082";
                    };
                };
                "jellyfin.anil.lc" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8096";
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
            };
        };
    };
}