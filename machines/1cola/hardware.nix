{ config, lib, pkgs, modulesPath, ... }: {
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    boot.initrd.availableKernelModules = [ "ata_piix" "ahci" "vmw_pvscsi" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
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
        device = "/dev/disk/by-uuid/19a130c5-e0b7-460f-bd7b-c05b0ede5502";
        fsType = "ext4";
    };
    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/55B0-21D2";
        fsType = "vfat";
    };
}
