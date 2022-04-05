{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    firewall.extraInputRules = "ip6 daddr ff02::1:6/128 accept";
    services.babeld-override = {
        enable = true;
        interfaces = flip mapAttrs (filterAttrs (name: value: hasPrefix "i" name) config.wg)
            (name: value: {
                type = "tunnel";
                v4-via-v6 = true;
                hello-interval = 2;
            });
        extraConfig = ''
            import-table 114
            export-table 254
            redistribute proto 114 allow
            redistribute local deny
            install             pref-src ${config.meta.v4}
            install ip fd00::/8 pref-src ${config.meta.v6}
            install pref-src 2602:feda:da0::${toHexString config.meta.id}
        '';
    };
    firewall.internalTCPPorts = [ 33124 ];
    systemd.services.babelweb2-port-forwarding = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = "${pkgs.socat}/bin/socat tcp6-listen:33124,fork,reuseaddr tcp:[::1]:33123";
    };
}