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
    networking.interfaces.ens3.useDHCP = true;
    net = {
        addresses = [
            { address = "2605:6400:20:677::/48"; interface = "ens3"; }
        ];
        routes = [
            { dst = "2605:6400:ffff::2/128"; src = "2605:6400:20:677::"; interface = "ens3"; }
        ];
        up = [ "ens3" ];
        gateway6 = "2605:6400:20::1";
    };
}
