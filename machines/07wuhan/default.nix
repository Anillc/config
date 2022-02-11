rec {
    meta = {
        id = "07";
        name = "wuhan";
        address = "wh.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-wuhan-private-key.path;
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        networking.hostName = meta.name;
        sops.defaultSopsFile = ./secrets.yaml;
    };
}