config: pkgs: builtins.foldl' (acc: x: acc // {
    "d${x.name}" = {
        privateKeyFile = config.bgp.meta.wg-private-key config;
        listenPort = x.listen;
        allowedIPsAsRoutes = false;
        ips = [ "fe80::2526/64" ];
        postSetup = ''
            ${pkgs.iproute2}/bin/ip addr add ${config.bgp.bgpSettings.dn42.v4}/32 peer ${x.v4} dev d${x.name}
        '';
        peers = [{
            inherit (x) publicKey endpoint presharedKey;
            persistentKeepalive = 25;
            allowedIPs = [
                "0.0.0.0/0"
                "::/0"
            ];
        }];
    };
}) {} config.bgp.bgpSettings.dn42.peers