rec {
    meta = {
        id = "01";
        name = "shanghai";
        address = "sh.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-shanghai-private-key.path;
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
    };
    configuration = { config, pkgs, ... }: {
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./asterisk.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-shanghai-private-key.sopsFile = ./secrets.yaml;
        sops.secrets = {
            anillc-device.sopsFile = ./secrets.yaml;
        };
        networking.hostName = meta.name;
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
        networking.wireguard.interfaces.phone = {
            privateKeyFile = meta.wg-private-key config;
            listenPort = 11451;
            allowedIPsAsRoutes = false;
            peers = [{
                publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
                persistentKeepalive = 25;
                allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                ];
            }];
        };
        systemd.services.phone-network = {
            wantedBy = [ "multi-user.target" ];
            partOf = [ "dummy.service" ];
            requires = [ "wireguard-phone.service" "network-online.target" ];
            after = [ "wireguard-phone.service" "network-online.target" ];
            script = ''
                ${pkgs.iproute2}/bin/ip route del 172.22.167.110/32 table 114 || true
                ${pkgs.iproute2}/bin/ip route del 2602:feda:da1::1/128 table 114 || true
                ${pkgs.iproute2}/bin/ip route del fd10:127:cc:1::1/128 table 114 || true
                ${pkgs.iproute2}/bin/ip route add 172.22.167.110/32 dev phone proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add 2602:feda:da1::1/128 dev phone proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add fd10:127:cc:1::1/128 dev phone proto 114 table 114
            '';
        };
        networking.firewall.extraCommands = ''
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8086 -s 172.22.167.96/27 -j nixos-fw-accept
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8086 -s 10.127.20.0/24 -j nixos-fw-accept

            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 6700 -s 172.22.167.96/27 -j nixos-fw-accept
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 6700 -s 10.127.20.0/24 -j nixos-fw-accept
        '';
        services.influxdb2.enable = true;
    };
}