{ config, pkgs, ... }: let
    sync-clash = pkgs.writeScript "sync-clash" ''
        export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
            wget gnused
        ]}
        ${config.sops.secrets.sync-clash.path}
        sed -i "0,/type: select/{s/type: select/type: url-test\n  url: http:\/\/api.telegram.org\n  interval: 300/}" /var/sync/clash/config.yaml
    '';
in {
    systemd.services.clash = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        preStart = "${sync-clash}";
        script = "${pkgs.clash}/bin/clash -d /var/sync/clash";
    };
}