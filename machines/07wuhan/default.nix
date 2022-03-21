lib: rec {
    machines = import ./.. lib;
    meta = {
        id = "07";
        name = "wuhan";
        address = "wh.an.dn42";
        inNat = true;
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
        v4 = "172.22.167.103";
        v6 = "fdc9:83c1:d0ce::7";
        connect = with machines.set; [ shanghai ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.defaultSopsFile = ./secrets.yaml;
    };
}