{ config, pkgs, lib, ... }: let
    cfg = config.bgp;
in {
    config = lib.mkIf cfg.enable {
        # TODO: babeld
        firewall.extraInputRules = "ip6 daddr ff02::1:6/128 accept";
        services.babeld = {
            enable = true;
            interfaces = builtins.foldl' (acc: x: acc // {
                "i${x.meta.name}".type = "tunnel";
            }) {} cfg.connect;
            extraConfig = ''
                reflect-kernel-metric true
                import-table 114
                export-table 32766
                redistribute proto 114 allow
                redistribute local deny
                install pref-src ${cfg.bgpSettings.dn42.v4}
                install ip fd00::/8 pref-src ${cfg.bgpSettings.dn42.v6}
                install pref-src 2602:feda:da0::${cfg.meta.id}
            '';
        };
    };
}