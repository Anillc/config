rec {
    machines = (import ./..).set;
    meta = {
        id = "06";
        name = "de";
        address = "de.an.dn42";
        inNat = true;
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
        v4 = "172.22.167.102";
        v6 = "fdc9:83c1:d0ce::6";
        connect = [ machines.lasvegas machines.hongkong machines.jp ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
    };
}