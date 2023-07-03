{ modulesPath, config, pkgs, lib, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ ];
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}