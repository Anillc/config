rec {
    meta = {
        id = "05";
        name = "shanghai2";
        address = "sh2.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-shanghai2-private-key.path;
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        networking.hostName = meta.name;
        sops.secrets.wg-shanghai2-private-key.sopsFile = ./secrets.yaml;
        sops.secrets = {
            cllina-device.sopsFile = ./secrets.yaml;
            bot-env = {
                format = "binary";
                sopsFile = ./bot.env;
            };
        };
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        services.go-cqhttp = {
            enable = true;
            device = config.sops.secrets.cllina-device.path;
            config.message.remove-reply-at = true;
        };
        services.mysql = {
            enable = true;
            package = pkgs.mariadb;
            initialDatabases = [{
                name = "bot";
            }];
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.bot = {
                image = "docker.io/anillc/cllina:b0d37b1";
                volumes = [
                    "/run/mysqld/mysqld.sock:/run/mysqld/mysqld.sock"
                    "${config.sops.secrets.bot-env.path}:/root/cllina/.env"
                    "/var/koishi:/root/cllina/.koishi"
                ];
                extraOptions = [ "--network=host" ];
            };
        };

        # Xiao Jin
        networking.wireguard.interfaces.xiaojin = {
            privateKeyFile = meta.wg-private-key config;
            allowedIPsAsRoutes = false;
            ips = [ "192.168.2.23/24" "fe80::2526/64" ];
            peers = [{
                endpoint = "shanghai-1.mchosts.com.cn:51820";
                publicKey = "EKU0tuuMyBSdbD95Z8f4J6BZt93UQbiEzHR+84DTcSk=";
                persistentKeepalive = 25;
                allowedIPs = [ "0.0.0.0/0" "::/0" ];
            }];
        };
        systemd.services.xiaojin-network = {
            wantedBy = [ "multi-user.target" ];
            partOf = [ "dummy.service" ];
            requires = [ "wireguard-xiaojin.service" "network-online.target" ];
            after = [ "wireguard-xiaojin.service" "network-online.target" ];
            script = ''
                ${pkgs.iproute2}/bin/ip route del 10.0.0.0/16         table 114 || true
                ${pkgs.iproute2}/bin/ip route del 192.168.2.0/24      table 114 || true
                ${pkgs.iproute2}/bin/ip route del 2a0e:b107:1171::/48 table 114 || true
                ${pkgs.iproute2}/bin/ip route add 10.0.0.0/16    via 192.168.2.19  proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add 192.168.2.0/24 via 192.168.2.19  proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add 2a0e:b107:1171::/48 dev xiaojin  proto 114 table 114
            '';
        };
    };
}