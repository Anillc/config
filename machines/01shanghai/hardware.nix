{ modulesPath, ... }: {
    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
    ];
    boot.loader.grub.device = "/dev/vda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
    };
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
}
