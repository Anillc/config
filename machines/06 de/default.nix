rec {
    meta = {
        id = "06";
        name = "de";
        address = "de.an.dn42";
        inNat = true;
        port = 22;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-de-private-key.path;
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-de-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
    };
}