{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    # TODO:
    networking.interfaces.ens18.ipv4.addresses = [{
        address = "10.56.1.12";
        prefixLength = 24;
    }];
    networking.interfaces.ens18.ipv6.addresses = [{
        address = "2404:f4c0:5156:1::12";
        prefixLength = 64;
    }];
    networking.interfaces.ens19.ipv6.addresses = [{
        address = "2406:840:1f:10::14:2055:1";
        prefixLength = 64;
    }];
    networking.defaultGateway = {
        address = "10.56.1.1";
        interface = "ens18";
    };
    networking.defaultGateway6 = {
        address = "2404:f4c0:5156:1::1";
        interface = "ens18";
    };
    networking.nameservers = [ "223.5.5.5" ];
}