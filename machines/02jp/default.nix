lib: rec {
    machines = import ./.. lib;
    meta = {
        id = "02";
        name = "jp";
        address = "jp.an.dn42";
        wg-public-key = "HcvaoEtLGxv1tETLCjmcKXkr1CNwiF/ZsmIi7lYAvQ4=";
        v4 = "172.22.167.99";
        v6 = "fdc9:83c1:d0ce::3";
        connect = with machines.set; [ hongkong lasvegas de ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.bot-env = {
                format = "binary";
                sopsFile = ./bot.env;
            };
        };
        bgp.enable = true;
        services.mysql = {
            enable = true;
            package = pkgs.mariadb;
            initialDatabases = [{
                name = "bot";
            }];
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.bot = {
                image = "docker.io/anillc/cllina:50a07d1";
                volumes = [
                    "/run/mysqld/mysqld.sock:/run/mysqld/mysqld.sock"
                    "${config.sops.secrets.bot-env.path}:/root/cllina/.env"
                    "/var/koishi:/root/cllina/.koishi"
                ];
                extraOptions = [ "--network=host" ];
            };
        };
        
        # bot telegram
        firewall.internalTCPPorts = [ 8056 ];
    };
}