{ config, pkgs, lib, ... }: with lib; let
    connect = builtins.map (x: (import ../../machines).validate pkgs.lib.evalModules x) config.meta.connect;
in {
    systemd.services.setup-wireguard = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "net.service" ];
        bindsTo = [ "net.service" ];
        script = pkgs.lib.strings.concatStringsSep "\n" (builtins.map (x: optionalString (!x.inNat) ''
            ENDPOINT=$(${pkgs.jq}/bin/jq -r '."${x.id}"' ${config.sops.secrets.endpoints.path})
            ${pkgs.wireguard-tools}/bin/wg set i${x.name} peer "${x.wg-public-key}" endpoint "$ENDPOINT:110${config.meta.id}"
        '') connect);
    };
    net.wg = builtins.foldl' (acc: x: acc // {
        "i${x.name}" = {
            listen = mkIf (!config.meta.inNat) (pkgs.lib.toInt "110${x.id}");
            ip = [
                { addr = "fe80::10${config.meta.id}/64"; }
                { addr = "169.254.233.1${config.meta.id}/24"; }
            ];
            publicKey = x.wg-public-key;
        };
    }) {} connect;
}