{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/vda";
    boot.initrd.kernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
    fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
    };
    fileSystems."/data" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    swapDevices = [{
        device = "/var/lib/swap";
    }];
}