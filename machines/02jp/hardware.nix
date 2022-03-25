{ config, lib, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
    boot.loader.grub.device = "/dev/vda";
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/10c29d28-2f97-4e4a-a110-698026da9779";
        fsType = "ext4";
    };
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    swapDevices = [{
        device = "/var/swapfile";
    }];
    networking.interfaces.enp1s0.useDHCP = true;
}