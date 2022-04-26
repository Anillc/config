{ config, lib, pkgs, modulesPath, ... }: {
    imports = [ ];
    boot.initrd.availableKernelModules = [ "ata_piix" "ahci" "vmw_pvscsi" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.loader.grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
    };
    boot.loader.efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
    };
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/c2da9304-bd89-49d9-940d-e79f1b2379fc";
        fsType = "ext4";
    };
    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/8A46-C7E2";
        fsType = "vfat";
    };
}