{ config, pkgs, ... }: {
    imports = [
        ./wg.nix
        ./nftables.nix
        ./babeld-override.nix
    ];
}