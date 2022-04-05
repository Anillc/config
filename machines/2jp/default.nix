lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 2;
        name = "jp";
        wg-public-key = "HcvaoEtLGxv1tETLCjmcKXkr1CNwiF/ZsmIi7lYAvQ4=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.bot-env = {
                format = "binary";
                sopsFile = ./bot.env;
            };
        };
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "64515";
                address = "2001:19f0:ffff::1";
                password = "TRgV3ytV38";
                multihop = true;
            };
        };
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