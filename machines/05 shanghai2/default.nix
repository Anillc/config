rec {
    meta = {
        id = "05";
        name = "shanghai2";
        address = "sh2.an.dn42";
        inNat = true;
        port = 22;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-shanghai2-private-key.path;
        wg-public-key = "RBjfmCcZywc4KhQA1Mv/hzm6+I52R0DrHPT7DzLzWGI=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.secrets.wg-shanghai2-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
    };
}