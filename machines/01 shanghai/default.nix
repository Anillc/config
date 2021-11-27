rec {
    meta = {
        id = "01";
        name = "shanghai";
        address = "sh.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-shanghai-private-key.path;
        wg-public-key = "82rDuI1+QXAXv+6HAf5aH2Ly0JXX/105Fsd61HmVnGE=";
    };
    configuration = { config, pkgs, ... }: {
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        imports = [
            ./hardware.nix
            ./asterisk.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-shanghai-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
        services.go-cqhttp = {
            enable = true;
            uin = config.sops.secrets.cllina-uin.path;
            password = config.sops.secrets.cllina-password.path;
            device = config.sops.secrets.cllina-device.path;
        };
        networking.wireguard.interfaces.phone = {
            privateKeyFile = meta.wg-private-key config;
            listenPort = 11451;
            allowedIPsAsRoutes = false;
            peers = [{
                publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
                persistentKeepalive = 25;
                allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                ];
            }];
        };
    };
}