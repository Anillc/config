rec {
    meta = {
        id = 7;
        name = "wh";
        enable = false;
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp = {
            enable = true;
            peers = {
                zxix1 = {
                    asn = "140961";
                    address = "2406:840:1f:10::1";
                };
                zxix2 = {
                    asn = "140961";
                    address = "2406:840:1f:10::2";
                };
            };
        };
        networking.nameservers = [ "223.5.5.5" ];
    };
}