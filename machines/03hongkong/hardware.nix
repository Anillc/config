{ config, lib, pkgs, modulesPath, ... }: {
    imports = [ ];
    boot.initrd.availableKernelModules = [ "ata_piix" "ahci" "vmw_pvscsi" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/0e0a3cb9-31e7-463d-b747-889ee42fa790";
        fsType = "ext4";
    };
    fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/A390-0EBB";
        fsType = "vfat";
    };
    swapDevices = [{ device = "/dev/disk/by-uuid/17ff6bd3-5a1d-4dab-a844-77c82656c18b"; }];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        addresses = [
            { addressConfig = { Address = "103.152.35.32/24"; }; }
            { addressConfig = { Address = "2406:4440::32/64"; }; }
        ];
        routes = [
            { routeConfig = { Gateway = "103.152.35.254"; }; }
            { routeConfig = { Gateway = "2406:4440::1"; }; }
        ];
    };
    networking.nameservers = [ "223.5.5.5" ];
}