rec {
    meta = {
        id = 8;
        name = "r";
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
        syncthingId = "HOQH4WA-6GIJL5H-YGGXMCL-YRFHFAP-TTMJN5R-5MEV2PH-Q3GWS6G-MGRGXA3";
    };
    configuration = { config, pkgs, lib, ... }: {
        cfg.meta = meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./flow.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network.mode = "0755";
            secrets.dnsmasq-static-map = {};
        };
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
    };
}