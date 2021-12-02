{ config, pkgs, lib, ... }: let
    cfg = config.bgp;
in {
    config = lib.mkIf cfg.enable {
        services.babeld = {
            enable = true;
            interfaces = builtins.foldl' (acc: x: acc // {
                "i${x.meta.name}" = {
                    type = "tunnel";
                    link-quality = true;
                    max-rtt-penalty = 1024;
                    rtt-max = 1024;
                    split-horizon = false;
                    hello-interval = 20;
                    rxcost = 32;
                };
            }) {} cfg.connect;
            extraConfig = ''
                redistribute proto 114 allow
                redistribute local deny
                install pref-src ${cfg.bgpSettings.dn42.v4}
                install ip fd00::/8 pref-src ${cfg.bgpSettings.dn42.v6}
                install pref-src 2602:feda:da0::${cfg.meta.id}
            '';
        };
    };
}