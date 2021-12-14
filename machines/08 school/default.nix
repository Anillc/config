rec {
    meta = {
        id = "08";
        name = "school";
        address = "jx.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-school-private-key.path;
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            ./networking.nix
            (import ./bgp.nix meta)
        ];
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.secrets = {
            wg-school-private-key.sopsFile = ./secrets.yaml;
            school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        networking.hostName = meta.name;
        systemd.services.school-network = {
            wantedBy = [ "multi-user.target" ];
            partOf = [ "dummy.service" ];
            after = [ "network-online.target" ];
            script = ''
                ${pkgs.iproute2}/bin/ip route del 10.127.20.128/25 table 114 || true
                ${pkgs.iproute2}/bin/ip route del 2602:feda:da1:1::/96 table 114 || true
                ${pkgs.iproute2}/bin/ip route del fd10:127:cc:1:1::/96 table 114 || true
                ${pkgs.iproute2}/bin/ip route add 10.127.20.128/25 dev br0 proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add 2602:feda:da1:1::/96 dev br0 proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add fd10:127:cc:1:1::/96 dev br0 proto 114 table 114
            '';
        };
    };
}