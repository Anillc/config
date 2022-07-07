{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    inherit (config.system.build) toplevel;
    db = pkgs.closureInfo { rootPaths = [ toplevel ]; };
    nixVar = pkgs.vmTools.runInLinuxVM (pkgs.runCommand "nixVar" {} ''
        mkdir -p $out
        ${pkgs.nix}/bin/nix-store --load-db < ${db}/registration
        ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --set "${toplevel}"
        mv /nix/var/* $out
    '');
in {
    system.build.tarball = pkgs.callPackage "${pkgs.nixpkgs}/nixos/lib/make-system-tarball.nix" {
        storeContents = [{
            object = config.system.build.toplevel;
            symlink = "none";
        }];
        contents = [
            {
                source = config.system.build.toplevel + "/init";
                target = "/sbin/init";
            }
            {
                source = nixVar;
                target = "/nix/var";
            }
        ];

        extraCommands = "mkdir -p root etc/systemd/network";
    };
    boot = {
        isContainer = true;
        loader.initScript.enable = true;
    };
    systemd.mounts = [{
        where = "/sys/kernel/debug";
        enable = false;
    }];
}