rec {
    meta = {
        id = "05";
        name = "shanghai2";
        address = "sh2.an.dn42";
        inNat = true;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-shanghai2-private-key.path;
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        networking.hostName = meta.name;
        sops.secrets.wg-shanghai2-private-key.sopsFile = ./secrets.yaml;
        sops.secrets = {
            cllina-uin.sopsFile = ./secrets.yaml;
            cllina-password.sopsFile = ./secrets.yaml;
            cllina-device.sopsFile = ./secrets.yaml;
        };
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        services.go-cqhttp = {
            enable = true;
            uin = config.sops.secrets.cllina-uin.path;
            password = config.sops.secrets.cllina-password.path;
            device = config.sops.secrets.cllina-device.path;
        };
    };
}