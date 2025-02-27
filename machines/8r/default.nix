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
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        systemd.services.qbittorrent = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = with pkgs; [ qbittorrent-nox ];
            script = "qbittorrent-nox";
        };
    };
}