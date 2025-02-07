{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    imports = [
        ./meta.nix
    ];
    system.stateVersion = "22.05";
    networking.hostName = mkDefault config.cfg.meta.name;
    time.timeZone = "Asia/Shanghai";
    cfg.firewall.publicTCPPorts = [ 22 ];
    services.iperf3.enable = true;
    users = {
        mutableUsers = false;
        users.root = {
            hashedPassword = "$6$8MxrAaylIOlYr0ff$oRKqD26AbwjtL8Scj4LEAL6Zdsz3Uu1RPLYHPC7jwP36SZql8CsDe4scccb58DTRpw38ixchRuU4b0uq7r68S/";
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqu43h92/UcQLf+E7AnUqmjjdGLkcazB9Z9nNRferqD tablet"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmgw6CGq5fPlVdJc5DhgXzlW2GSimAd1xiRbEZWS0KG phone"
            ];
        };
    };
    nix = {
        extraOptions = ''
            experimental-features = nix-command flakes
        '';
        optimise.automatic = true;
        settings = {
            auto-optimise-store = true;
            substituters = [ "https://anillc.cachix.org" ];
            trusted-public-keys = [
                "anillc.cachix.org-1:VmWDYKHoDiT0CKs+6daDcTz3Ur+gkw4k0kcHIeF6dF8="
            ];
        };
        gc = {
            automatic = true;
            options = "--delete-older-than 5d";
            dates = "Sun 6:00";
        };
    };
    services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
    };
    environment.systemPackages = with pkgs; [
        vim traceroute mtr socat tcpdump dig wireguard-tools
    ];
    sops = {
        age.keyFile = "/var/lib/sops.key";
        secrets.endpoints.sopsFile = ./secrets.yaml;
        secrets.wg-private-key = {
            owner = "systemd-network";
            group = "systemd-network";
        };
    };
    documentation.enable = false;
    security.acme = {
        acceptTerms = true;
        defaults.email = "void@anil.lc";
    };
}