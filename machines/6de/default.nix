lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 6;
        name = "de";
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        networking.nameservers = [ "8.8.8.8" ];
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "135395";
                address = "2a0f:9400:7a00::1";
            };
        };
    };
}