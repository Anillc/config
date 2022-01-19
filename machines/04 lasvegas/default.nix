rec {
    meta = {
        id = "04";
        name = "lasvegas";
        address = "las.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-lasvegas-private-key.path;
        wg-public-key = "NQfs6evQLemuJcdcvpO4ds1wXwUHTlzlQXWTJv+WCXY=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-lasvegas-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
        dns.enable = true;
        networking.wireguard.interfaces.deploy = {
            privateKeyFile = meta.wg-private-key config;
            listenPort = 12001;
            allowedIPsAsRoutes = false;
            peers = [{
                publicKey = "QQZ7pArhUyhdYYDhlv+x3N4G/+Uwu9QAdbWoNWAIRGg=";
                persistentKeepalive = 25;
                allowedIPs = [ "0.0.0.0/0" "::/0" ];
            }];
        };
        systemd.services.deploy-network = {
            wantedBy = [ "multi-user.target" ];
            partOf = [ "dummy.service" ];
            requires = [ "wireguard-deploy.service" "network-online.target" ];
            after = [ "wireguard-deploy.service" "network-online.target" ];
            script = ''
                ${pkgs.iproute2}/bin/ip route del 10.127.20.114/32 table 114 || true
                ${pkgs.iproute2}/bin/ip route add 10.127.20.114/32 dev deploy proto 114 table 114
            '';
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
        networking.firewall.extraCommands = ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -s 10.127.3.0/24 -d 172.22.167.96/27 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -A FORWARD -s 10.127.3.0/24 -d 10.0.2.0/24 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -A FORWARD -s 10.127.3.0/24 -j DROP
            ${pkgs.iptables}/bin/iptables -A FORWARD -j ACCEPT
        '';
        networking.firewall.extraStopCommands = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -s 10.127.3.0/24 -d 172.22.167.96/27 -j ACCEPT || true
            ${pkgs.iptables}/bin/iptables -D FORWARD -s 10.127.3.0/24 -d 10.0.2.0/24 -j ACCEPT      || true
            ${pkgs.iptables}/bin/iptables -D FORWARD -s 10.127.3.0/24 -j DROP                       || true
            ${pkgs.iptables}/bin/iptables -D FORWARD -j ACCEPT                                      || true
        '';
    };
}