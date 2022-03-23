lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 9;
        name = "fmt";
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
        connect = with machines.set; [ las de ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        networking.nameservers = [ "8.8.8.8" ];
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