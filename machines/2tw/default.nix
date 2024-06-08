rec {
    meta = {
        id = 2;
        name = "tw";
        wg-public-key = "tQRTS5f+rRulwjf9zTlJ7Gtf9sONb+DKq4s6nsPvQXA=";
        syncthingId = "LBFAGHZ-E5MMLTP-5JJRV7H-3VRVDG2-NBP45WQ-WKDYK3L-HB2WDGK-VBCG7AC";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
    };
}