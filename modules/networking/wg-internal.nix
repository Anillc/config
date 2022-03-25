{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    connect = map (x: x.meta) config.meta.connect;
in {
    systemd.services.setup-wireguard = {
        wantedBy = [ "multi-user.target" "net.service" ];
        after = [ "network-online.target" "net.service" ];
        partOf = [ "net.service" ];
        path = with pkgs; [ wireguard-tools jq ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
        };
        script = pkgs.lib.strings.concatStringsSep "\n" (map (x: optionalString (!x.inNat) ''
            # wait for starting the net service
            sleep 2
            ENDPOINT=$(jq -r '."${toString x.id}"' ${config.sops.secrets.endpoints.path})
            wg set i${x.name} peer "${x.wg-public-key}" endpoint "$ENDPOINT:${toString (11000 + config.meta.id)}"
        '') connect);
    };
    net.wg = listToAttrs (map (x: nameValuePair "i${x.name}" {
        listen = mkIf (!config.meta.inNat) (11000 + x.id);
        publicKey = x.wg-public-key;
    }) connect);
    net.addresses = flatten (map (x: [
        { interface = "i${x.name}"; address = "fe80::${toHexString config.meta.id}/64"; }
        { interface = "i${x.name}"; address = "169.254.233.${toString config.meta.id}/24"; }
    ]) connect);
}