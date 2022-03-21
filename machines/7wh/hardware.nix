{ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
    boot.loader.grub.device = "/dev/sda";
    boot.initrd.kernelModules = [ "nvme" ];
    fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
    };
    net = {
        addresses = [
            { address = "10.56.1.12/24";                interface = "ens18"; }
            { address = "2404:f4c0:5156:1::12/64";      interface = "ens18"; }
            { address = "2406:840:1f:10::14:2055:1/64"; interface = "ens19"; }
        ];
        up = [ "ens18" "ens19" ];
        gateway4 = "10.56.1.1";
        gateway6 = "2404:f4c0:5156:1::1";
    };
}