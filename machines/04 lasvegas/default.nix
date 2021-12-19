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
        systemd.services.firewall-influxdb = {
            wantedBy = [ "multi-user.target" ];
            partOf = [ "firewall.service" ];
            requires = [ "firewall.service" ];
            after = [ "firewall.service" "network-online.target" ];
            script = ''
                ${pkgs.iptables}/bin/iptables -D nixos-fw -j nixos-fw-log-refuse
                ${pkgs.iptables}/bin/iptables -D nixos-fw -p tcp --dport 8086 -s 172.22.167.96/27 -j nixos-fw-accept || true
                ${pkgs.iptables}/bin/iptables -D nixos-fw -p tcp --dport 8086 -s 10.127.20.0/24 -j nixos-fw-accept || true
                ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8086 -s 172.22.167.96/27 -j nixos-fw-accept
                ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8086 -s 10.127.20.0/24 -j nixos-fw-accept
                ${pkgs.iptables}/bin/iptables -A nixos-fw -j nixos-fw-log-refuse
            '';
        };
        services.influxdb2 = {
            enable = true;
        };
    };
}