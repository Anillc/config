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
    networking.interfaces.ens160.useDHCP = true;
    net = {
        addresses = [
            { address = "2a0f:9400:7a00:1111:8ba5::/48";  interface = "ens160"; }
            { address = "2a0f:9400:7a00:3333:f81c::1/64"; interface = "ens160"; }
        ];
        up = [ "ens160" ];
        gateway4 = "2a0f:9400:7a00::1";
    };
    networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
}