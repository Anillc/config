rec {
    meta = {
        id = 5;
        name = "sh2";
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./networking.nix
            ./nanahira.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.cllina-device = {};
            secrets.cllina-environment = {};
            secrets.zinc-environment = {};
            secrets.wg-nanahira-private-key = {};
        };
        bgp.enable = true;

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

        services.zinc = {
            enable = true;
            environmentFile = config.sops.secrets.zinc-environment.path;
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
    };
}