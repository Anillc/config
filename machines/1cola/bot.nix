{ config, pkgs, lib, inputs, ... }:

{
    systemd.tmpfiles.rules = [
        "d /var/lib/chronocat 0700 root root"
    ];
    systemd.services.chronocat = {
        enable = false;
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            WorkingDirectory = "/var/lib/chronocat";
            ExecStart = "${inputs.chronocat-nix.packages.x86_64-linux.default}/bin/chronocat";
        };
    };
}