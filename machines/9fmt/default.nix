lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 9;
        name = "fmt";
        enable = false;
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "7720";
                address = "2602:fc1d:0:2::1";
                multihop = true;
            };
        };
    };
}