{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    swapDevices = [{
        device = "/var/swapfile";
    }];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens160";
        DHCP = "ipv4";
        addresses = [
            { addressConfig = { Address = "2a0f:9400:7a00:1111:8ba5::/48"; }; }
            { addressConfig = { Address = "2a0f:9400:7a00:3333:f81c::1/64"; }; }
        ];
        routes = [{ routeConfig = { Gateway = "2a0f:9400:7a00::1"; }; }];
    };
    networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
}