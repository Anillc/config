{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    networking.interfaces.ens160.ipv6.addresses = [{
        address = "2a0f:9400:7a00:1111:8ba5::";
        prefixLength = 48;
    }];
    networking.interfaces.ens192.ipv6.addresses = [{
        address = "2a0f:9400:7a00:3333:f81c::1";
        prefixLength = 64;
    }];
    networking.defaultGateway6 = {
        address = "2a0f:9400:7a00::1";
        interface = "ens160";
    };
}