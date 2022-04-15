{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    imports = [
        ./meta.nix
    ];
    networking.hostName = config.meta.name;
    time.timeZone = "Asia/Shanghai";
    firewall.publicTCPPorts = [ 22 ];
    services.iperf3.enable = true;
    users = {
        mutableUsers = false;
        users.root = {
            hashedPassword = "$6$8MxrAaylIOlYr0ff$oRKqD26AbwjtL8Scj4LEAL6Zdsz3Uu1RPLYHPC7jwP36SZql8CsDe4scccb58DTRpw38ixchRuU4b0uq7r68S/";
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWwUAfQr3i3TYkQEIfgdZJSFdJ9vuxfZh8zHFl2wkXh deploy"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYipJTFX3ViRLx/0/vDyxe9N6dhuiJjPZqom0kSB5ix i@anillc.cn"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB585948akMZJJeh2R/PsaHc80+/3zqrz4wBQnYaujF phone"
            ];
        };
    };
    nix = {
        package = pkgs.nixUnstable;
        extraOptions = ''
            experimental-features = nix-command flakes
        '';
        optimise.automatic = true;
        settings.auto-optimise-store = true;
        gc = {
            automatic = true;
            options = "--delete-older-than 5d";
            dates = "Sun 6:00";
        };
    };
    services.openssh = {
        enable = true;
        passwordAuthentication = false;
    };
    environment.systemPackages = with pkgs; [
        vim traceroute mtr socat tcpdump dig wireguard-tools
    ];
    sops = {
        age.keyFile = "/var/lib/sops.key";
        secrets.endpoints.sopsFile = ./secrets.yaml;
        secrets.sync-database = {
            mode = "0700";
            sopsFile = ./secrets.yaml;
        };
        secrets.wg-private-key = {
            owner = "systemd-network";
            group = "systemd-network";
        };
    };
    documentation.enable = false;
    security.acme.defaults.email = "acme@anillc.cn";
    security.acme.acceptTerms = true;
    services.nscd.enable = false;
    system.nssModules = mkForce [];
    services.cron = let
        script = pkgs.writeScript "sync" ''
            export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
                wget
            ]}
            ${config.sops.secrets.sync-database.path}
        '';
    in {
        enable = true;
        systemCronJobs = [
            "*/20 * * * * root ${script}"
        ];
    };
}