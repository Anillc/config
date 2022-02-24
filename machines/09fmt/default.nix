rec {
    machines = (import ./..).set;
    meta = {
        id = "09";
        name = "fmt";
        address = "fmt.an.dn42";
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
        v4 = "172.22.167.108";
        v6 = "fdc9:83c1:d0ce::12";
        connect = [ machines.lasvegas ];
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