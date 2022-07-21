rec {
    meta = {
        id = 6;
        name = "de";
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
        syncthingId = "W5FM2IT-LYKZ2UR-JVZX6EF-3R6GCSY-QEYZ43X-WJZNFY3-3RMIMLU-DBPSJAH";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "135395";
                address = "2a0f:9400:7a00::1";
            };
        };
    };
}