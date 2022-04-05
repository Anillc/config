lib: rec {
    meta = {
        id = 1;
        name = "sh";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.anillc-device = {};
            secrets.anillc-environment = {};
        };
        bgp.enable = true;
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
            nodes = builtins.map (x: "[${x.v6}]:33124") (map (x: x.meta) (import ../. lib).list);
        };
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            virtualHosts = {
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