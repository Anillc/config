{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    imports = [
        ./meta.nix
    ];
    system.stateVersion = "22.05";
    networking.hostName = config.meta.name;
    time.timeZone = "Asia/Shanghai";
    firewall.publicTCPPorts = [ 22 ];
    services.iperf3.enable = true;
    users = {
        mutableUsers = false;
        users.root = {
            hashedPassword = "$6$8MxrAaylIOlYr0ff$oRKqD26AbwjtL8Scj4LEAL6Zdsz3Uu1RPLYHPC7jwP36SZql8CsDe4scccb58DTRpw38ixchRuU4b0uq7r68S/";
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGbuvvxj+2wbzl6KUKSbDLA2QHwoS+dL+tO3mEcTAMw i@anillc.cn"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWwUAfQr3i3TYkQEIfgdZJSFdJ9vuxfZh8zHFl2wkXh deploy"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB585948akMZJJeh2R/PsaHc80+/3zqrz4wBQnYaujF phone"
            ];
        };
    };
    nix = {
        package = pkgs.nixUnstable;
        nixPath = [ "nixpkgs=${pkgs.nixpkgs}" ];
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
    nixpkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) [
        "youtrack"
    ];
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
        secrets.wg-private-key = {
            owner = "systemd-network";
            group = "systemd-network";
        };
    };
    documentation.enable = false;
    services.nscd.enable = false;
    system.nssModules = mkForce [];
    boot.kernelModules = [ "vrf" ];
    security.pki.certificates = [
        ''
            -----BEGIN CERTIFICATE-----
            MIIBuDCCAV6gAwIBAgIRAN4mUTU29kmR6Frd/mxdBI8wCgYIKoZIzj0EAwIwOjEX
            MBUGA1UEChMOQW5pbGxjIE5ldHdvcmsxHzAdBgNVBAMTFkFuaWxsYyBOZXR3b3Jr
            IFJvb3QgQ0EwHhcNMjIwNDIzMTU1MzMzWhcNMzIwNDIwMTU1MzMzWjA6MRcwFQYD
            VQQKEw5BbmlsbGMgTmV0d29yazEfMB0GA1UEAxMWQW5pbGxjIE5ldHdvcmsgUm9v
            dCBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNVhfPh+481EdmHfpE15TJZ1
            HRuTimaBeQ+W4rWKDTXJ4Nhqz46j8vvJ7KsMYvIPR0j7k+2AZsAb9h99duH2FPOj
            RTBDMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEBMB0GA1UdDgQW
            BBTCA7ZQ7hdNmYKwmmpnJ8PP+zhU4jAKBggqhkjOPQQDAgNIADBFAiAmNo5TVoX0
            TYsI+A1iQcT5WnGyejD0dvgOxDEBVdcg8QIhANjWSjihlT/6/DKq9QeslU8eNnVW
            Jw7M2hlSAfUFq1/0
            -----END CERTIFICATE-----
        ''
    ];
}