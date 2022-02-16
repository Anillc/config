rec {
    machines = (import ./..).set;
    meta = {
        id = "01";
        name = "shanghai";
        address = "sh.an.dn42";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        v4 = "172.22.167.105";
        v6 = "fdc9:83c1:d0ce::9";
        connect = [ machines.hongkong machines.shanghai2 machines.wuhan machines.school machines.lasvegas ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.anillc-device = {};
        };
        # influxdb and go-cqhttp
        firewall.internalTCPPorts = [ 8086 6700 ];
        services.influxdb2.enable = true;
        services.go-cqhttp = {
            enable = true;
            device = config.sops.secrets.anillc-device.path;
            config.message.remove-reply-at = true;
            config.servers = [{
                ws = {
                    host = "0.0.0.0";
                    port = 6700;
                };
            }];
        };
        services.babelweb2 = {
            enable = true;
            nodes = builtins.map (x: "[${x.v6}]:33124") ((import ../.).metas pkgs.lib.evalModules);
        };
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            virtualHosts = {
                "lg.anillc.cn" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:5000";
                    };
                };
                "babeld.anillc.cn" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8080";
                        proxyWebsockets = true;
                    };
                };
            };
        };
        wg.phone = {
            listen = 11451;
            publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
        };
        systemd.network.networks.phone-network = {
            matchConfig.Name = "phone";
            routes = [
                { routeConfig = { Destination = "172.22.167.110/32"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "2602:feda:da1::1/128"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "fd10:127:cc:1::1/128"; Table = 114; Protocol = 114; }; }
            ];
        };
    };
}