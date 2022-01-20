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
    networking.interfaces.ens3.ipv6.addresses = [{
        address = "2605:6400:20:677::";
        prefixLength = 48;
    }];
    networking.defaultGateway6 = {
        address = "2605:6400:20::1";
        interface = "ens3";
    };
}
