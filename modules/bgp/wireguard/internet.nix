config: pkgs: builtins.foldl' (acc: x: acc // {
    "e${x.name}" = {
        privateKeyFile = config.bgp.meta.wg-private-key config;
        listenPort = x.listen;
        allowedIPsAsRoutes = false;
        ips = [ "fe80::2526/64" ];
        peers = [{
            inherit (x) publicKey endpoint presharedKey;
            persistentKeepalive = 25;
            allowedIPs = [
                "0.0.0.0/0"
                "::/0"
            ];
        }];
    };
}) {} config.bgp.bgpSettings.internet.peers