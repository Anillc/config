{ modulesPath, config, pkgs, lib, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" "rtsx_usb_sdmmc" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ rtl88x2bu zfs ];
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = [ "/dev/sda" ];
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/c13b1282-76d0-4a3d-8b8f-90b101d8aab1";
        fsType = "ext4";
    };
}