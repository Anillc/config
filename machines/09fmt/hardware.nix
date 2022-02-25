{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    boot.kernel.sysctl = {
        "accept_ra" = 2;
    };
    net = {
        addresses = [
            { address = "208.99.48.169/24"; interface = "ens18"; }
        ];
        up = [ "ens18" ];
        gateway4 = "208.99.48.1";
    };
}