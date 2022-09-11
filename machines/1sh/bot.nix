{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    services.go-cqhttp = {
        enable = false;
        device = config.sops.secrets.cllina-device.path;
        environmentFile = config.sops.secrets.cllina-environment.path;
        config = {
            message = {
                remove-reply-at = true;
                skip-mime-scan = true;
            };
            account = {
                uin = "\${UIN}";
                password = "\${PASSWORD}";
            };
        };
    };
    services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        initialDatabases = [{
            name = "bot";
        }];
    };
    services.mysqlBackup = {
        enable = true;
        databases = [ "bot" ];
        user = "syncthing";
    };
    sync = [ "/var/backup/mysql" ];
    services.telegraf.extraConfig.mysql.servers = [ "$MYSQL_SERVER" ];
    virtualisation.oci-containers = {
        backend = "podman";
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
    systemd.services."container@bot".after = [ "mysql.service" ];
    containers.bot = {
        autoStart = false;
        bindMounts."/run/secrets" = {};
        bindMounts."/run/mysqld/mysqld.sock" = {};
        config = {
            system.stateVersion = "22.05";
            documentation.enable = false;
            networking.firewall.enable = false;
            fonts.fonts = with pkgs; [
                jetbrains-mono
                source-han-sans
            ];
            systemd.services.bot = {
                wantedBy = [ "multi-user.target" ];
                environment = {
                    SECRETS = config.sops.secrets."bot-secrets.json".path;
                    http_proxy = "http://127.0.0.1:7890";
                    https_proxy = "http://127.0.0.1:7890";
                    no_proxy = "10.11.0.1,127.0.0.1,a";
                };
                script = ''
                    mkdir -p /var/lib/bot && cd /var/lib/bot
                    ${inputs.cllina.packages.${pkgs.system}.default}/bin/cllina
                '';
            };
        };
    };
}