{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    boot.kernel.sysctl = {
        # "net.ipv6.conf.ens18.accept_ra" = 2;
    };
    net = {
        addresses = [
            { address = "208.99.48.169/24"; interface = "ens18"; }
            { address = "2602:fc1d:0:2:20e6:51ff:fe23:64f3/64"; interface = "ens18"; }
        ];
        # routes = [
        #     { dst = "2602:fc1d::1/128"; src = "2602:fc1d:0:2:20e6:51ff:fe23:64f3"; interface = "ens18"; }
        # ];
        up = [ "ens18" ];
        gateway4 = "208.99.48.1";
        gateway6 = "2602:fc1d:0:2::1";
    };
}