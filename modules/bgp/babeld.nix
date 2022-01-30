{ config, pkgs, lib, ... }: let
    cfg = config.bgp;
in {
    config = lib.mkIf cfg.enable {
        # babeld
        networking.firewall.extraCommands = "${pkgs.iptables}/bin/ip6tables -A nixos-fw -d ff02::1:6/128 -j nixos-fw-accept";
        networking.firewall.extraStopCommands = "${pkgs.iptables}/bin/ip6tables -D nixos-fw -d ff02::1:6/128 -j nixos-fw-accept";
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