{ config, pkgs, lib, ... }: with lib; let
    cfg = config.bgp;
in {
    config = lib.mkIf config.bgp.enable {
        wg = (builtins.foldl' (acc: x: acc // {

            # dn42 interfaces
            "d${x.name}" = {
                ip = [
                    { addr = "fe80::2526/64"; }
                    (pkgs.lib.mkIf (x.v4 != null) {
                        addr = "${config.meta.v4}/32";
                        peer = "${x.v4}/32";
                    })
                ];
                inherit (x) publicKey endpoint listen refresh presharedKeyFile;
            };

        }) {} config.bgp.bgpSettings.dn42.peers)
        // (builtins.foldl' (acc: x: acc // {

            # internet interfaces
            "e${x.name}" = {
                ip = [{ addr = "fe80::2526/64"; }];
                inherit (x) publicKey endpoint listen refresh presharedKeyFile;
            };

        }) {} config.bgp.bgpSettings.internet.peers);
    };
}