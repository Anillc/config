lib: rec {
    machines = import ./.. lib;
    meta = {
        id = "08";
        name = "school";
        address = "jx.an.dn42";
        inNat = true;
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        v4 = "172.22.167.107";
        v6 = "fdc9:83c1:d0ce::11";
        connect = with machines.set; [ shanghai ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
    };
}