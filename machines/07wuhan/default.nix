rec {
    machines = (import ./..).set;
    meta = {
        id = "07";
        name = "wuhan";
        address = "wh.an.dn42";
        inNat = true;
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
        connect = [ machines.shanghai ];
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