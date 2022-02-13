rec {
    meta = {
        id = "08";
        name = "school";
        address = "jx.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-school-private-key.path;
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        disabled = true;
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            ./networking.nix
            (import ./bgp.nix meta)
        ];
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        networking.hostName = meta.name;
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