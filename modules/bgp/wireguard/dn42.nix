config: pkgs: builtins.foldl' (acc: x: acc // {
    "d${x.name}" = {
        ip = [
            { addr = "fe80::2526/64"; }
            (pkgs.lib.mkIf (x.v4 != null) {
                addr = "${config.bgp.bgpSettings.dn42.v4}/32";
                peer = "${x.v4}/32";
            })
        ];
        refresh = pkgs.lib.mkIf (x ? refresh) x.refresh;
        inherit (x) publicKey endpoint listen;
    };
}) {} config.bgp.bgpSettings.dn42.peers