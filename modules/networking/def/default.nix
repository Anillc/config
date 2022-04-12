{ config, pkgs, ... }: {
    imports = [
        ./wg.nix
        ./firewall.nix
        ./babeld-override.nix
    ];
}