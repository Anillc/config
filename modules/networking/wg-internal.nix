{ config, pkgs, lib, ... }: with lib; {
    systemd.services.setup-wireguard = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        bindsTo = [ "systemd-networkd.service" ];
        script = pkgs.lib.strings.concatStringsSep "\n" (builtins.map (x: optionalString (!x.meta.inNat) ''
            ENDPOINT=$(${pkgs.jq}/bin/jq -r '."${x.meta.id}"' ${config.sops.secrets.endpoints.path})
            ${pkgs.wireguard-tools}/bin/wg set i${x.meta.name} peer "${x.meta.wg-public-key}" endpoint "$ENDPOINT:110${config.bgp.meta.id}"
        '') config.bgp.connect);
    };
    wg = builtins.foldl' (acc: x: acc // {
        "i${x.meta.name}" = {
            listen = mkIf (!config.bgp.meta.inNat) (pkgs.lib.toInt "110${x.meta.id}");
            ip = [
                { addr = "fe80::10${config.bgp.meta.id}/64"; }
                { addr = "169.254.233.1${config.bgp.meta.id}/24"; }
            ];
            publicKey = x.meta.wg-public-key;
        };
    }) {} config.bgp.connect; # TODO: rename bgp.connect
}