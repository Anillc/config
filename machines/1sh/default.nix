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
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.anillc-device = {};
            secrets.anillc-environment = {};
            secrets.cllina-device = {};
            secrets.cllina-environment = {};
            secrets.bot-secrets = {};
            secrets.grafana-smtp = {
                owner = "grafana";
                group = "grafana";
            };
        };
        bgp.enable = true;
        services.youtrack.enable = true;
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
        services.go-cqhttp = {
            enable = true;
            device = config.sops.secrets.cllina-device.path;
            environmentFile = config.sops.secrets.cllina-environment.path;
            config = {
                message.remove-reply-at = true;
                account = {
                    uin = "\${UIN}";
                    password = "\${PASSWORD}";
                };
            };
        };
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
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
                "yt.anillc.cn" = {
                    extraConfig = ''
                        location / {
                              proxy_pass http://127.0.0.1:8080;
                              proxy_set_header Host $host;
                              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                              proxy_set_header X-Forwarded-Proto "https";
                              proxy_set_header X-Forwarded-Host "yt.anillc.cn:443";
                              proxy_set_header X-Forwarded-Server $host;
                        }
                    '';
                };
            };
        };
    };
}
