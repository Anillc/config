{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.clash;
    sync-clash = pkgs.writeScript "sync-clash" ''
        export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
            wget gnused
        ]}
        ${config.sops.secrets.sync-clash.path}
        sed -i "0,/type: select/{s/type: select/type: url-test\n  url: http:\/\/google.com\n  interval: 300/}" /var/lib/clash/config.yaml
    '';
in {
    options.clash.enable = mkEnableOption "enable clash";
    config = mkIf (cfg.enable) {
        sops.secrets.sync-clash = {
            sopsFile  = ./secrets.yaml;
            mode = "0700";
        };
        systemd.services.clash = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            preStart = "${sync-clash}";
            script = "${pkgs.clash}/bin/clash -d /var/lib/clash";
        };
    };
}