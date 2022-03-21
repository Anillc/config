lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 1;
        name = "sh";
        address = "sh.an.dn42";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        connect = with machines.set; [ hk sh2 wh jx las ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.anillc-device = {};
            secrets.anillc-environment = {};
        };
        # influxdb and go-cqhttp
        firewall.internalTCPPorts = [ 8086 6700 ];
        services.influxdb2.enable = true;
        services.go-cqhttp = {
            enable = true;
            device = config.sops.secrets.anillc-device.path;
            environmentFile = config.sops.secrets.anillc-environment.path;
            config = {
                message.remove-reply-at = true;
                account = {
                    uin = "\${UIN}";
                    password = "\${PASSWORD}";
                };
            };
        };
        services.babelweb2 = {
            enable = true;
            nodes = builtins.map (x: "[${x.v6}]:33124") (map (x: x.meta) machines.list);
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
        # TODO
        # net.wg.phone = {
        #     listen = 11451;
        #     publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
        # };
        # net.routes = [
        #     { dst = "172.22.167.110/32";    interface = "phone"; proto = 114; table = 114; }
        #     { dst = "2602:feda:da1::1/128"; interface = "phone"; proto = 114; table = 114; }
        #     { dst = "fd10:127:cc:1::1/128"; interface = "phone"; proto = 114; table = 114; }
        # ];
    };
}