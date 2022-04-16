rec {
    meta = {
        id = 8;
        name = "jx";
        wg-public-key = "2YSajirzbCUK4h3NbuBgpZPOypjrhtrLnT5pJp2K9HU=";
    };
    configuration = { config, pkgs, lib, ... }:
    
    with builtins;
    with lib;

    let
        china-ip = filter (x: x != "") (splitString "\n" (readFile "${pkgs.china-ip}/china_ip_list.txt"));
    in {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.school-network = {
                mode = "0755";
                sopsFile = ./secrets.yaml;
            };
        };
        bgp.enable = true;
    };
}