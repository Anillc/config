rec {
    meta = {
        id = "06";
        name = "de";
        address = "de.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
    };
}