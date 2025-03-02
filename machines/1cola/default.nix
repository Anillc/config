rec {
    meta = {
        id = 1;
        name = "cola";
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
        syncthingId = "3LP4IIZ-VEMIMAP-SGB7O7Q-JXRZZBM-DOYOGOK-P3K4BMK-YVA2KNL-TDR3UAI";
    };
    configuration = { config, pkgs, lib, inputs, ... }: {
        cfg.meta = meta;
        networking.hostName = "Anillc-linux";
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.rsshub = {};
        };
        nix.settings.substituters = lib.mkBefore [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        virtualisation.vmware.guest = {
            enable = true;
            headless = true;
        };
        cfg.firewall.publicTCPPorts = [ 16801 80 ];
        services.openssh.ports = [ 16801 22 ];
        services.restic.server = {
            enable = true;
            listenAddress = "8081";
            extraFlags = [ "--no-auth" ];
            dataDir = "/backup/restic";
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.rsshub = {
                image = "docker.io/diygod/rsshub:chromium-bundled";
                ports = [ "8082:1200" ];
                environmentFiles = [ config.sops.secrets.rsshub.path ];
            };
        };
        systemd.tmpfiles.rules = [
            "d /var/lib/chronocat 0700 root root"
        ];
        systemd.services.chronocat = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                WorkingDirectory = "/var/lib/chronocat";
                ExecStart = "${inputs.chronocat-nix.packages.x86_64-linux.default}/bin/chronocat";
            };
        };
    };
}
