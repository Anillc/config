rec {
    meta = {
        id = "02";
        name = "jp";
        address = "jp.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-public-key = "HcvaoEtLGxv1tETLCjmcKXkr1CNwiF/ZsmIi7lYAvQ4=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.bot-env = {
                format = "binary";
                sopsFile = ./bot.env;
            };
        };
        networking.hostName = meta.name;
        networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

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
                image = "docker.io/anillc/cllina:7b53827";
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