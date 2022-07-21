{ config, lib, ... }:

with builtins;
with lib;

let
    selfName = config.meta.name;
    repo = name: "/var/lib/syncthing/${name}";
    machines = import ../../machines lib;
    otherDevices = filterAttrs (name: value: name != config.meta.name) machines.set;
in {
    options.sync = mkOption {
        type = types.listOf types.str;
        description = "sync folders";
        default = [];
    };
    config = {
        sops.secrets.syncthing-restic = {
            sopsFile = ./secrets.yaml;
            owner = "syncthing";
            group = "syncthing";
        };
        services.restic.backups.${selfName} = {
            initialize = true;
            user = "syncthing";
            repository = repo selfName;
            passwordFile = config.sops.secrets.syncthing-restic.path;
            paths = config.sync;
            timerConfig = {
                OnCalendar = "daily";
            };
        };
        services.syncthing = {
            enable = true;
            guiAddress = "0.0.0.0:8384";
            devices = mapAttrs (name: value: {
                name = value.meta.name;
                id = value.meta.syncthingId;
                addresses = [ "tcp://${value.meta.v4}:22000" ];
            }) otherDevices;
            folders = {
                "${selfName}" = {
                    path = repo selfName;
                    devices = attrNames otherDevices;
                };
            } // mapAttrs (name: value: {
                path = repo name;
                devices = [ name ];
            }) otherDevices;
        };
    };
}