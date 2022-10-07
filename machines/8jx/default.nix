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
        ];
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        bgp.enable = true;
        systemd.services.qbittorrent = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = with pkgs; [ qbittorrent-nox ];
            script = "qbittorrent-nox";
        };
        # services.home-assistant = {
        #     enable = true;
        #     config = {
        #         frontend = {};
        #         homeassistant = {
        #             name = "school";
        #             unit_system = "metric";
        #             time_zone = "Asia/Shanghai";
        #         };
        #         http = {
        #             use_x_forwarded_for = true;
        #             trusted_proxies = [ "127.0.0.1" ];
        #         };
        #     };
        # };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                # "ha.a" = {
                #     enableACME = true;
                #     forceSSL = true;
                #     locations."/" = {
                #         proxyWebsockets = true;
                #         proxyPass = "http://127.0.0.1:8123";
                #     };
                # };
                "qb.a" = {
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