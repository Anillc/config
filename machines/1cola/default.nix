rec {
    meta = {
        id = 1;
        name = "cola";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        syncthingId = "3LP4IIZ-VEMIMAP-SGB7O7Q-JXRZZBM-DOYOGOK-P3K4BMK-YVA2KNL-TDR3UAI";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        networking.hostName = "Anillc-linux";
        nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./networking.nix
            ./synapse.nix
            ./bot.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.bot-secrets = {};
            secrets.rsshub = {};
            secrets.grafana-smtp = {
                owner = "grafana";
                group = "grafana";
            };
        };
        virtualisation.vmware.guest = {
            enable = true;
            headless = true;
        };
        firewall.publicTCPPorts = [ 16801 80 ];
        services.openssh.ports = [ 16801 22 ];
        services.influxdb2.enable = true;
        services.grafana = {
            enable = true;
            settings.smtp = {
                enable = true;
                user = "alert@anillc.cn";
                host = "smtp.ym.163.com:25";
                passwordFile = config.sops.secrets.grafana-smtp.path;
                fromAddress = "alert@anillc.cn";
            };
        };
        services.restic.server = {
            enable = true;
            listenAddress = "127.0.0.1:8081";
            extraFlags = [ "--no-auth" ];
            dataDir = "/backup/restic";
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.rsshub = {
                image = "docker.io/diygod/rsshub:chromium-bundled";
                ports = [ "8082:1200" ];
                environmentFiles = [ config.sops.secrets.rsshub.path ];
            };
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            clientMaxBodySize = "0";
            virtualHosts = {
                "bot.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8056";
                    };
                };
                "panel.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:3000";
                    };
                };
                "db.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8444";
                    };
                };
                "influxdb.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8086";
                    };
                };
                "biliapi.a" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
                "restic.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8081";
                    };
                };
            };
        };
    };
}
