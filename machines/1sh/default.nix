rec {
    meta = {
        id = 1;
        name = "sh";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        syncthingId = "7HJSITB-P5CUWIN-VTLC47V-NGBDCMQ-KOJIGE6-WI7IXFF-TGOXITC-STZQHQ2";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./networking.nix
            ./bot.nix
            ./bot2.nix
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
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "k8s.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "https://10.11.3.1:32727";
                        extraConfig = ''
                            proxy_ssl_verify off;
                        '';
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
                "bot.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8056";
                    };
                };
                "biliapi.a" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
            };
        };
        rsrc = {
            enable = true;
            cidr = "2a0e:b107:1172::/56";
            proxy = "https://[240e:978:1503::240]";
            proxyHost = "api.vc.bilibili.com";
        };
    };
}
