rec {
    meta = {
        id = 8;
        name = "jx";
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./flow.nix
        ];
        nix.settings.substituters = lib.mkForce [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        bgp.enable = true;
        services.home-assistant = {
            enable = true;
            config = {
                frontend = {};
                homeassistant = {
                    name = "school";
                    unit_system = "metric";
                    time_zone = "Asia/Shanghai";
                };
            };
        };
    };
}