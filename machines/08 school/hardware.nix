{ modulesPath, config, pkgs, lib, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" "rtsx_usb_sdmmc" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = [ "/dev/sda" ];
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/c9d0d3cf-690e-4665-a201-b231aa417d48";
        fsType = "ext4";
    };
}