rec {
    meta = {
        id = 6;
        name = "nnhr";
        wg-public-key = "IY76y7a8L+58gFUWmhuAcedUvzSxmG7cshRRwzNHmXM=";
        syncthingId = "TNLEMYT-MGBHESP-FEPBNG6-QYEZTIC-QKFIUQN-MXDUIYU-PXCPHV6-KDV5FQZ";
    };
    configuration = { config, pkgs, lib, inputs, ... }: let
        pkgs-meilisearch = import inputs.nixpkgs-meilisearch { inherit (pkgs) system; };
    in {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
    };
}