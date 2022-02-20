{ config, lib, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.loader.grub.device = "/dev/sda";
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/1992d070-731f-4885-a766-f3b4b7115c74";
        fsType = "ext4";
    };
    fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/8790-8D0F";
        fsType = "vfat";
    };
    swapDevices = [ { device = "/dev/disk/by-uuid/51154ad0-0ef7-491a-a5c9-8132eedaad9c"; } ];
    net = {
        addresses = [
            { address = "192.168.1.110/24"; interface = "ens18"; }
        ];
        up = [ "ens18" ];
        gateway4 = "192.168.1.1";
    };
    networking.nameservers = [ "223.5.5.5" ];
}