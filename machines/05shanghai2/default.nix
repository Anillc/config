rec {
    machines = (import ./..).set;
    meta = {
        id = "05";
        name = "shanghai2";
        address = "sh2.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
        connect = [ machines.shanghai machines.hongkong ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./nanahira.nix
            ./bgp.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.cllina-device = {};
            secrets.wg-nanahira-private-key = {
                owner = "systemd-network";
                group = "systemd-network";
            };
        };
        
        # gocq
        firewall.internalTCPPorts = [ 6700 ];
        services.go-cqhttp = {
            enable = true;
            device = config.sops.secrets.cllina-device.path;
            config.message.remove-reply-at = true;
            config.servers = [{
                ws = {
                    host = "0.0.0.0";
                    port = 6700;
                };
            }];
        };

        services.cron.systemCronJobs = [ "0 0 * * * root ${pkgs.systemd}/bin/systemctl restart podman-xxqg" ];
        virtualisation.oci-containers = {
            backend = "podman";
            containers.xxqg = {
                image = "docker.mirror.aliyuncs.com/techxuexi/techxuexi-amd64";
                environment = {
                    ZhuanXiang = "True";
                    Pushmode = "6";
                };
                ports = [ "8080:80" ];
                extraOptions = [ "--shm-size=2g" ];
            };
        };

        firewall.publicTCPPorts = [ 80 25565 ];
        services.nginx = {
            enable = true;
            virtualHosts = {
                "xxqg.anillc.cn" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
            };
        };
        # Xiao Jin
        systemd.network.networks.default-network = {
            routes = [
                { routeConfig = { Gateway = "192.168.1.1"; Destination = "10.0.0.0/16"; PreferredSource = "172.22.167.106"; Table = 114; Protocol = 114; GatewayOnLink = "yes"; }; }
                { routeConfig = { Gateway = "192.168.1.1"; Destination = "192.168.2.0/24"; PreferredSource = "172.22.167.106"; Table = 114; Protocol = 114; GatewayOnLink = "yes"; }; }
                { routeConfig = { Gateway = "192.168.1.1"; Destination = "192.168.22.0/24"; PreferredSource = "172.22.167.106"; Table = 114; Protocol = 114; GatewayOnLink = "yes"; }; }
            ];
        };
    };
}