rec {
    machines = (import ./..).set;
    meta = {
        id = "04";
        name = "lasvegas";
        address = "las.an.dn42";
        wg-public-key = "NQfs6evQLemuJcdcvpO4ds1wXwUHTlzlQXWTJv+WCXY=";
        v4 = "172.22.167.97";
        v6 = "fdc9:83c1:d0ce::1";
        connect = [ machines.hongkong machines.de machines.shanghai machines.jp ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
            ./dns.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.traefik = {};
            secrets.wg-yuuta-preshared-key = {
                owner = "systemd-network";
                group = "systemd-network";
            };
        };
        dns.enable = true;

        traefik = {
            enable = true;
            configFile = config.sops.secrets.traefik.path;
        };

        wg.deploy = {
            listen = 12001;
            publicKey = "QQZ7pArhUyhdYYDhlv+x3N4G/+Uwu9QAdbWoNWAIRGg=";
        };
        systemd.network.networks.deploy-network = {
            matchConfig.Name = "deploy";
            routes = [
                { routeConfig = { Destination = "10.127.20.114/32"; Table = 114; Protocol = 114; }; }
            ];
        };
        systemd.services.tayga = let
            conf = pkgs.writeText "tayga" ''
                tun-device nat64
                ipv4-addr 10.127.3.1
                dynamic-pool 10.127.3.0/24
                prefix 2a0e:b107:1171::/96
            '';
        in {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
                ${pkgs.tayga}/bin/tayga --mktun --config ${conf}
                ${pkgs.iproute2}/bin/ip link set nat64 up
                ${pkgs.iproute2}/bin/ip route del 10.127.3.0/24 table 114 || true
                ${pkgs.iproute2}/bin/ip route del 2a0e:b107:1171::/96 || true
                ${pkgs.iproute2}/bin/ip route add 10.127.3.0/24 dev nat64 proto 114 table 114
                ${pkgs.iproute2}/bin/ip route add 2a0e:b107:1171::/96 dev nat64
                ${pkgs.tayga}/bin/tayga --nodetach --config ${conf}
            '';
        };
        # tayga
        firewall.extraForwardRules = ''
            ip saddr 10.127.3.0/24 ip daddr {
                172.22.167.96/27,
                10.0.2.0/24,
                172.23.0.80/32,
            } accept
            ip saddr 10.127.3.0/24 drop
        '';
    };
}