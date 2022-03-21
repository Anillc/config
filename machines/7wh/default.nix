lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 7;
        name = "wh";
        address = "wh.an.dn42";
        inNat = true;
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
        connect = with machines.set; [ sh ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.defaultSopsFile = ./secrets.yaml;
    };
}