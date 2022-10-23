rec {
    meta = {
        id = 4;
        name = "koishi";
        wg-public-key = "++8g+U89u77H0EbWI81j20CKKeSp7eY847M30sI2XFg=";
        syncthingId = "44JIF3B-D3EIAAE-F36UOOA-PM5CMFP-X2VZNQ3-5ZPPMCI-CIQDINJ-J5TRVQL";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./discourse.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
                discourse-admin = {
                    owner = "discourse";
                    group = "discourse";
                };
                discourse-mail = {
                    owner = "discourse";
                    group = "discourse";
                };
            };
        };
        bgp.enable = true;
    };
}
