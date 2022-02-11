{ pkgs, ... }: {
    imports = [
        ./nftables.nix
        ./wg.nix
        ./wg-internal.nix
    ];
    systemd.network.enable = true;
}