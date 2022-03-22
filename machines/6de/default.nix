lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 6;
        name = "de";
        address = "de.awsl.ee";
        inNat = true;
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
        connect = with machines.set; [ las hk jp fmt ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        networking.nameservers = [ "8.8.8.8" ];
    };
}