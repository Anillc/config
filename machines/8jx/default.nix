rec {
    meta = {
        id = 8;
        name = "jx";
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        syncthingId = "KJ32DJV-6GEUEF6-AFXYFBD-MWCUJR3-HGORURZ-ZH2H556-FLM67O2-Z3RMYQJ";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./flow.nix
        ];
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        # nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network.mode = "0755";
            secrets.dnsmasq-static-map = {};
            secrets.hass-secrets = {
                owner = "hass";
                group = "hass";
            };
        };
        system.activationScripts.hass-secrets = lib.mkIf config.services.home-assistant.enable {
            deps = [ "setupSecrets" ];
            text = ''
                ln -sf ${config.sops.secrets.hass-secrets.path} ${config.services.home-assistant.configDir}/secrets.yaml
                chown -R hass:hass ${config.services.home-assistant.configDir}/secrets.yaml
            '';
        };
        bgp.enable = true;
        systemd.services.qbittorrent = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = with pkgs; [ qbittorrent-nox ];
            script = "qbittorrent-nox";
        };
        services.home-assistant = {
            enable = true;
            extraComponents = [ "xiaomi" ];
            config = {
                frontend = {};
                homeassistant = {
                    name = "school";
                    unit_system = "metric";
                    time_zone = "Asia/Shanghai";
                };
                http = {
                    use_x_forwarded_for = true;
                    trusted_proxies = [ "127.0.0.1" ];
                };
                mobile_app = {};
                device_tracker = [{
                    platform = "xiaomi";
                    host = "!secret router-ip";
                    password = "!secret router-password";
                }];
                automation = "!include automations.yaml";
            };
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "ha.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8123";
                    };
                };
                "qb.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
                "bot2.a" = {
                    locations."/".proxyPass = "http://10.11.2.133:8005";
                };
            };
        };
    };
}