rec {
    meta = {
        id = "03";
        name = "hongkong";
        address = "hk.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-hongkong-private-key.path;
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-hongkong-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
        systemd.services.nat64 = let
            taygaConfig = pkgs.writeText "config" ''
                tun-device nat64
                ipv4-addr 192.168.115.1
                prefix 2602:feda:da0:64::/96
                dynamic-pool 192.168.115.0/24
                data-dir /var/db/tayga
            '';
        in {
            description = "nat64";
            before = [ "bird2.service" ];
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            script = ''
                ${pkgs.iproute2}/bin/ip link del nat64
                ${pkgs.tayga}/bin/tayga --config ${taygaConfig} --mktun
                ${pkgs.iproute2}/bin/ip link set nat64 up
                ${pkgs.iproute2}/bin/ip addr add 192.168.116.1/32 dev nat64
                ${pkgs.iproute2}/bin/ip route add 192.168.115.0/24 dev nat64
                ${pkgs.iproute2}/bin/ip addr add 2602:feda:da0::3/128 dev nat64
                ${pkgs.iptables}/bin/iptables -A POSTROUTING -t nat -o ens192 -s 192.168.115.0/24 -j MASQUERADE
                ${pkgs.tayga}/bin/tayga -d --config ${taygaConfig}
            '';
        };
        networking.resolvconf.useLocalResolver = false;
        services.smartdns = {
            enable = true;
            bindPort = 8053;
            settings = {
                server = [ "8.8.8.8" "8.8.4.4" ];
                force-AAAA-SOA = "yes";
            };
        };
        services.bind = {
            enable = true;
            forwarders = [
                "127.0.0.1 port 8053"
            ];
            cacheNetworks = [ "any" ];
            extraOptions = ''
                dnssec-enable yes;
                dnssec-validation no;
                dns64 2602:feda:da0:64::/96 {
                    clients { any; };
                };
            '';
        };
    };
}