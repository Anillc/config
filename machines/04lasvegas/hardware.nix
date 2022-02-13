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
        matchConfig.Name = "ens3";
        DHCP = "ipv4";
        addresses = [{ addressConfig = { Address = "2605:6400:20:677::/48"; }; }];
        routes = [{ routeConfig = { Gateway = "2605:6400:20::1"; }; }];
    };
    networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
}
