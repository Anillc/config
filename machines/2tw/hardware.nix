{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    boot = {
        isContainer = true;
        loader.initScript.enable = true;
    };
    systemd.mounts = [{
        where = "/sys/kernel/debug";
        enable = false;
    }];
}