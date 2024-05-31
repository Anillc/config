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
    system.build.tarball = pkgs.callPackage "${inputs.nixpkgs}/nixos/lib/make-system-tarball.nix" {
        storeContents = [{
            object = config.system.build.toplevel;
            symlink = "none";
        }];
        contents = [{
            source = config.system.build.toplevel + "/init";
            target = "/sbin/init";
        } {
            source = nixVar;
            target = "/nix/var";
        }];
        extraCommands = "mkdir -p root etc/systemd/network";
    };

    boot.loader.grub.device = mkDefault "/dev/vda";
    system.build.image = pkgs.vmTools.runInLinuxVM (pkgs.runCommand "image" {
        preVM = ''
            mkdir -p $out
            diskImage=$out/nixos.img
            ${pkgs.vmTools.qemu}/bin/qemu-img create -f raw $diskImage $(( $(cat ${db}/total-nar-size) + 500000000 ))
        '';
        nativeBuildInputs = with pkgs; [
            e2fsprogs mount util-linux nix nixos-install-tools
        ];
    } ''
        sfdisk /dev/vda <<EOF
        label: dos
        type=83, size=+, bootable
        EOF
        mkfs.ext4 /dev/vda1
        mkdir /mnt && mount /dev/vda1 /mnt
        export NIX_STATE_DIR=$TMPDIR/state
        nix-store --load-db < ${db}/registration
        nixos-install --root /mnt --system ${toplevel} --no-channel-copy --no-root-passwd --substituters ""
    '');
}