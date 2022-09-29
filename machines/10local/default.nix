rec {
    meta = {
        id = 10;
        name = "local";
        wg-public-key = "CgOCUZ1MqcazTdnVNu+RmFPaaBm+mV6/rzi+7ez263Q=";
        syncthingId = "6KISUZM-KKKDNF2-UN3LDOW-52676NR-EVF4P5C-CSOJ2ML-UYI3XG7-VHEQTQZ";
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