rec {
    meta = {
        id = 4;
        name = "koishi";
        wg-public-key = "++8g+U89u77H0EbWI81j20CKKeSp7eY847M30sI2XFg=";
        syncthingId = "44JIF3B-D3EIAAE-F36UOOA-PM5CMFP-X2VZNQ3-5ZPPMCI-CIQDINJ-J5TRVQL";
        # enable = false;
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
        };
        bgp.enable = true;
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
        };
    };
}
