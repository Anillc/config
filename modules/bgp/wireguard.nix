{ pkgs, config, lib, ... }: with lib; let
    cfg = config.bgp;
    intranet =  builtins.foldl' (acc: x: acc // {
        "i${x.meta.name}" = {
            privateKeyFile = cfg.meta.wg-private-key config;
            listenPort = if cfg.meta.inNat then null else pkgs.lib.toInt "110${x.meta.id}";
            allowedIPsAsRoutes = false;
            ips = [
                "fe80::10${cfg.meta.id}/64"
                "169.254.233.1${cfg.meta.id}/24"
            ];
            peers = [{
                publicKey = x.meta.wg-public-key;
                persistentKeepalive = 25;
                endpoint = if x.meta.inNat then null else "${x.meta.address}:110${cfg.meta.id}";
                allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                ];
            }];
        };
    }) {} cfg.connect;
    internet = builtins.foldl' (acc: x: acc // {
        "e${x.name}" = {
            privateKeyFile = cfg.meta.wg-private-key config;
            listenPort = if x.listen != null then x.listen else null;
            allowedIPsAsRoutes = false;
            ips = [ "fe80::2526/64" ];
            peers = [{
                inherit (x) publicKey;
                presharedKey = if x.presharedKey != null then x.presharedKey else null;
                persistentKeepalive = 25;
                endpoint = if x.endpoint != null then x.endpoint else null;
                allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                ];
            }];
        };
    }) {} cfg.bgpSettings.internet.peers;
    dn42 = builtins.foldl' (acc: x: acc // {
        "d${x.name}" = {
            privateKeyFile = cfg.meta.wg-private-key config;
            listenPort = if x.listen != null then x.listen else null;
            allowedIPsAsRoutes = false;
            ips = [ "fe80::2526/64" ];
            postSetup = ''
                ${pkgs.iproute2}/bin/ip addr add ${cfg.bgpSettings.dn42.v4}/32 peer ${x.v4} dev d${x.name}
            '';
            peers = [{
                inherit (x) publicKey;
                presharedKey = if x.presharedKey != null then x.presharedKey else null;
                persistentKeepalive = 25;
                endpoint = if x.endpoint != null then x.endpoint else null;
                allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                ];
            }];
        };
    }) {} cfg.bgpSettings.dn42.peers;
in {
    config = mkIf cfg.enable {
        networking.wireguard = {
            enable = true;
            interfaces = intranet // internet // dn42;
        };
    };
}