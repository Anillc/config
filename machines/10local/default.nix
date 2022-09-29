rec {
    meta = {
        id = 10;
        name = "local";
        wg-public-key = "CgOCUZ1MqcazTdnVNu+RmFPaaBm+mV6/rzi+7ez263Q=";
        syncthingId = "";
        enable = false;
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp.enable = true;
        k3s.enable = false;
    };
}