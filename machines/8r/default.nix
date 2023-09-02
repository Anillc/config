rec {
    meta = {
        id = 8;
        name = "r";
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        syncthingId = "HOQH4WA-6GIJL5H-YGGXMCL-YRFHFAP-TTMJN5R-5MEV2PH-Q3GWS6G-MGRGXA3";
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
        };
        bgp.enable = true;
        systemd.services.qbittorrent = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = with pkgs; [ qbittorrent-nox ];
            script = "qbittorrent-nox";
        };
        services.mosquitto = {
            enable = true;
            listeners = [{
                acl = [ "pattern readwrite #" ];
                omitPasswordAuth = true;
                settings.allow_anonymous = true;
            }];
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "qb.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
                "bot2.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://10.11.2.140:8005";
                    };
                };
            };
        };
    };
}