lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 5;
        name = "sh2";
        address = "sh2.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
        connect = with machines.set; [ sh ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            # ./nanahira.nix TODO
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.cllina-device = {};
            secrets.cllina-environment = {};
            secrets.wg-nanahira-private-key = {};
        };
        
        # gocq
        firewall.internalTCPPorts = [ 6700 ];
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
        # Xiao Jin TODO
        # net.routes = [
        #     { dst = "10.0.0.0/16";     src = "172.22.167.106"; interface = "ens18"; gateway = "192.168.1.1"; onlink = true; proto = 114; table = 114; }
        #     { dst = "192.168.2.0/24";  src = "172.22.167.106"; interface = "ens18"; gateway = "192.168.1.1"; onlink = true; proto = 114; table = 114; }
        #     { dst = "192.168.22.0/24"; src = "172.22.167.106"; interface = "ens18"; gateway = "192.168.1.1"; onlink = true; proto = 114; table = 114; }
        # ];
    };
}