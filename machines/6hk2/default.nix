rec {
    meta = {
        id = 6;
        name = "hk2";
        wg-public-key = "vj9hsGL/32BbhNuBreUHomdWSUjkuHeuqiCPPYQ+JBk=";
        syncthingId = "RDBLFVV-TR3RNNG-UZ3J3N6-HBDCYV4-EAHYKOC-6ITDHJW-X4UXGJK-7SGK6QX";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp.enable = true;
    };
}