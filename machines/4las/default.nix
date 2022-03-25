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
        services.frr-override.static = {
            enable = true;
            config = ''
                ! Buyvm Router
                ipv6 route 2605:6400:ffff::/64 fe80::4e96:1400:c8a8:5ff0 ens3
                ! Buyvm Gateway
                ipv6 route 2604:4d40:2000::/64 fe80::4e96:1400:c8a8:5ff0 ens3
                ! Buyvm Customers
                ipv6 route 2605:6400:20::/48 fe80::4e96:1400:c8a8:5ff0 ens3
                ! He
                ipv6 route 2001:470:1:964::1/128 fe80::4e96:1400:c8a8:5ff0 ens3
                ! Cogent
                ipv6 route 2001:550:2:c8::28:1/128 fe80::4e96:1400:c8a8:5ff0 ens3
                ! GTT
                ipv6 route 2001:668:0:3:ffff:2:0:1c6d/128 fe80::4e96:1400:c8a8:5ff0 ens3
                ! anyNode
                ipv6 route fdeb:fc8d:4786:60b7::2/128 fe80::4e96:1400:c8a8:5ff0 ens3
            '';
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