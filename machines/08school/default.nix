rec {
    machines = (import ./..).set;
    meta = {
        id = "08";
        name = "school";
        address = "jx.an.dn42";
        inNat = true;
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        v4 = "172.22.167.107";
        v6 = "fdc9:83c1:d0ce::11";
        connect = [ machines.shanghai ];
        enable = false;
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./bgp.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        systemd.network.networks.school-network = {
            matchConfig.Name = "br0";
            routes = [
                { routeConfig = { Destination = "10.127.20.128/25"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "2602:feda:da1:1::/96"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "fd10:127:cc:1:1::/96"; Table = 114; Protocol = 114; }; }
            ];
        };
        # dhcp
        firewall.extraInputRules = "ip saddr 0.0.0.0/32 accept";
    };
}