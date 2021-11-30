{ pkgs, ... }: {
    users = {
        mutableUsers = false;
        users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWwUAfQr3i3TYkQEIfgdZJSFdJ9vuxfZh8zHFl2wkXh deploy"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYipJTFX3ViRLx/0/vDyxe9N6dhuiJjPZqom0kSB5ix i@anillc.cn"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB585948akMZJJeh2R/PsaHc80+/3zqrz4wBQnYaujF phone"
        ];
    };
    nix.gc = {
        automatic = true;
        options = "--delete-older-than 5d";
        dates = "Sun 6:00";
    };
    services.openssh.enable = true;
    networking.firewall.enable = false;
    environment.systemPackages = with pkgs; [
        vim traceroute tcpdump dig
    ];
    sops = {
        age.keyFile = "/var/lib/sops.key";
        defaultSopsFile = ./secrets.yaml;
        secrets.endpoints = {};
    };
}