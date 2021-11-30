rec {
    meta = {
        id = "03";
        name = "hongkong";
        address = "hk.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-hongkong-private-key.path;
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-hongkong-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
    };
}