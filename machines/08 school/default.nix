rec {
    meta = {
        id = "08";
        name = "school";
        address = "jx.an.dn42";
        inNat = true;
        port = 22;
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
    };
}