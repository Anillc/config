rec {
    meta = {
        id = "02";
        name = "beijing";
        address = "bj.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-beijing-private-key.path;
        wg-public-key = "Ze6NjRj4i22gtpoE16mvvrrreI5SkIx4BbIUdcx3E0s=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        nix.binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
        sops.secrets.wg-beijing-private-key.sopsFile = ./secrets.yaml;
        networking.hostName = meta.name;
        virtualisation.oci-containers = {
            backend = "podman";
            containers.xxqg = {
                image = "docker.mirror.aliyuncs.com/techxuexi/techxuexi-amd64";
                environment = {
                    ZhuanXiang = "True";
                    Pushmode = "6";
                };
                ports = [ "8080:80" ];
                extraOptions = [ "--shm-size=2g" ];
            };
        };
        services.nginx = {
            enable = true;
            virtualHosts = {
                "xxqg.anillc.cn" = {
                    forceSSL = true;
                    enableACME = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8080";
                    };
                };
            };
        };
    };
}