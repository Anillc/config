{ config, pkgs, ... }: {
    imports = [
        ./net.nix
        ./wg.nix
        ./nftables.nix
        ./babeld-override.nix
        ./frr-override.nix
    ];
}