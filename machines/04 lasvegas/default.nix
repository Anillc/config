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
            script = ''
                ${pkgs.iproute2}/bin/ip route del 10.127.20.114/32 || true
                ${pkgs.iproute2}/bin/ip route add 10.127.20.114/32 dev deploy proto 114
            '';
        };
    };
}