{ config, pkgs, ... }: let
    sync-clash = pkgs.writeScript "sync-clash" ''
        export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
            wget
        ]}
        ${config.sops.secrets.sync-clash.path}
    '';
in {
    services.cron = {
        enable = true;
        systemCronJobs = [ "0 * * * * root ${sync-clash}" ];
    };
    systemd.services.clash = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        preStart = "${sync-clash}";
        script = "${pkgs.clash}/bin/clash -d /var/sync/clash";
    };
}