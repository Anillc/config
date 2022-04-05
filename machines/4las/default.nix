lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 4;
        name = "las";
        wg-public-key = "NQfs6evQLemuJcdcvpO4ds1wXwUHTlzlQXWTJv+WCXY=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.traefik = {};
            secrets.wg-yuuta-preshared-key = {
                owner = "systemd-network";
                group = "systemd-network";
            };
        };
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "53667";
                address = "2605:6400:ffff::2";
                password = "yfAnvncg";
                multihop = true;
            };
        };
        # traefik = {
        #     enable = true;
        #     configFile = config.sops.secrets.traefik.path;
        # };
    };
}