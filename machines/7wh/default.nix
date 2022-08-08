rec {
    meta = {
        id = 7;
        name = "wh";
        wg-public-key = "xUjqZwuOHxg4FOzU/W6y4/sNpRC/ux7duj5PBscIKTQ=";
        syncthingId = "XMDWVT7-LD6NGIP-JTJ2H5E-4KDEIHI-MWP6QTI-P3CV7EH-PZBHAOS-K3RO6AE";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
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
        random-src = {
            enable = true;
            igp = "fd11:1::5";
            prefix = "2a0e:b107:1172::";
            length = 56;
        };
    };
}