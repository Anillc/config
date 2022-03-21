{ config, pkgs, lib, ... }: {
    firewall.extraInputRules = "ip6 daddr ff02::1:6/128 accept";
    services.babeld-override = {
        enable = true;
        interfaces = builtins.foldl' (acc: x: acc // {
            "i${x.meta.name}".type = "tunnel";
        }) {} config.meta.connect;
        extraConfig = ''
            reflect-kernel-metric true
            import-table 114
            export-table 32766
            redistribute proto 114 allow
            redistribute local deny
            install pref-src ${config.meta.igpv4}
            install pref-src ${config.meta.igpv6}
        '';
    };
    firewall.internalTCPPorts = [ 33124 ];
    systemd.services.babelweb2-port-forwarding = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = "${pkgs.socat}/bin/socat tcp6-listen:33124,fork,reuseaddr tcp:[::1]:33123";
    };
}