{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        addresses = [
            { addressConfig = { Address = "10.56.1.12/24"; }; }
            { addressConfig = { Address = "2404:f4c0:5156:1::12"; }; }
        ];
        routes = [
            { routeConfig = { Gateway = "10.56.1.1"; }; }
            { routeConfig = { Gateway = "2404:f4c0:5156:1::1"; }; }
        ];
    };
    systemd.network.networks.default-network2 = {
        matchConfig.Name = "ens19";
        addresses = [{ addressConfig = { Address = "2406:840:1f:10::14:2055:1/64"; }; }];
    };
    networking.nameservers = [ "223.5.5.5" ];
}