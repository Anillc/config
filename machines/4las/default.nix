lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 4;
        name = "las";
        wg-public-key = "NQfs6evQLemuJcdcvpO4ds1wXwUHTlzlQXWTJv+WCXY=";
        connect = with machines.set; [ hk de jp fmt ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
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
        # net.wg.deploy = {
        #     listen = 12001;
        #     publicKey = "QQZ7pArhUyhdYYDhlv+x3N4G/+Uwu9QAdbWoNWAIRGg=";
        # };
        # TODO
        # net.routes = [
        #     { dst = "10.127.20.114/32"; interface = "deploy"; proto = 114; table = 114; }
        # ];
    };
}