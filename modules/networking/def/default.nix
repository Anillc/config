{ config, pkgs, ... }: {
    imports = [
        ./wg.nix
        ./firewall.nix
        ./frr-override.nix
    ];
}