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
    services.telegraf.extraConfig.mysql.servers = [ "$MYSQL_SERVER" ];
    virtualisation.oci-containers = {
        backend = "podman";
        containers.bot = {
            image = "docker.io/anillc/cllina:794f9a5";
            volumes = [
                "/run/mysqld/mysqld.sock:/run/mysqld/mysqld.sock"
                "${config.sops.secrets.bot-secrets.path}:/root/cllina/secrets.dhall"
                "/var/koishi:/root/cllina/.koishi"
            ];
            environment = {
                http_proxy = "http://127.0.0.1:7890";
                https_proxy = "http://127.0.0.1:7890";
                no_proxy = "10.11.0.1,10.11.0.5,127.0.0.1,a";
            };
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