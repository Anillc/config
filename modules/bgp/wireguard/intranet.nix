config: pkgs: builtins.foldl' (acc: x: acc // {
    "i${x.meta.name}" = {
        privateKeyFile = config.bgp.meta.wg-private-key config;
        listenPort = if config.bgp.meta.inNat then null else pkgs.lib.toInt "110${x.meta.id}";
        allowedIPsAsRoutes = false;
        ips = [
            "fe80::10${config.bgp.meta.id}/64"
            "169.254.233.1${config.bgp.meta.id}/24"
        ];
        peers = [{
            publicKey = x.meta.wg-public-key;
            persistentKeepalive = 25;
            allowedIPs = [
                "0.0.0.0/0"
                "::/0"
            ];
        }];
    };
}) {} config.bgp.connect