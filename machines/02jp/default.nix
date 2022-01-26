rec {
    meta = {
        id = "02";
        name = "jp";
        address = "jp.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-jp-private-key.path;
        wg-public-key = "HcvaoEtLGxv1tETLCjmcKXkr1CNwiF/ZsmIi7lYAvQ4=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-jp-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
    };
}