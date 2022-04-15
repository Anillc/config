{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
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
            image = "docker.io/anillc/cllina:ca1cead";
            volumes = [
                "/run/mysqld/mysqld.sock:/run/mysqld/mysqld.sock"
                "${config.sops.secrets.bot-env.path}:/root/cllina/.env"
                "/var/koishi:/root/cllina/.koishi"
            ];
            extraOptions = [ "--network=host" ];
        };
        containers.pma = {
            image = "docker.io/library/phpmyadmin";
            volumes = [
                "/run/mysqld/mysqld.sock:/tmp/mysql.sock"
            ];
            environment = {
                PMA_HOST = "localhost";
            };
            ports = [ "8444:80" ];
        };
    };
}