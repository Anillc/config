{ config, pkgs, ... }: {
    imports = [
        ./wg.nix
        ./firewall.nix
    ];
}