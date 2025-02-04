{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/85b1603b-70c7-4728-a58b-fc7ce95e5cc9";
        fsType = "xfs";
    };
}