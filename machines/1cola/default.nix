rec {
    meta = {
        id = 1;
        name = "cola";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        syncthingId = "3LP4IIZ-VEMIMAP-SGB7O7Q-JXRZZBM-DOYOGOK-P3K4BMK-YVA2KNL-TDR3UAI";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./networking.nix
            ./bot.nix
            ./bot2.nix
            ./synapse.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.anillc-device = {};
            secrets.anillc-environment = {};
            secrets.cllina-device = {};
            secrets.cllina-environment = {};
            secrets."bot-secrets.json" = {};
            secrets.grafana-smtp = {
                owner = "grafana";
                group = "grafana";
            };
        };
        bgp.enable = true;
        firewall.publicTCPPorts = [ 16801 80 ];
        services.openssh.ports = [ 16801 22 ];
        services.influxdb2.enable = true;
        services.grafana = {
            enable = true;
            addr = "0.0.0.0";
            smtp = {
                enable = true;
                user = "alert@anillc.cn";
                host = "smtp.ym.163.com:25";
                passwordFile = config.sops.secrets.grafana-smtp.path;
                fromAddress = "alert@anillc.cn";
            };
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "bot.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
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
            };
        };
    };
}
