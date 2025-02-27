{ config, lib, ... }:

with builtins;
with lib;

let
    selfName = config.cfg.meta.name;
    repo = name: "/var/lib/syncthing/${name}";
    machines = import ../../machines lib;
    otherDevices = filterAttrs (name: value: name != config.cfg.meta.name) machines.set;
in {
    services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = {
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