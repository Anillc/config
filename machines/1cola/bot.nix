{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    services.go-cqhttp = {
        enable = true;
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
    # TODO: pma and selfUrl
    virtualisation.oci-containers = {
        backend = "podman";
        containers.pma = {
            image = "docker.io/library/phpmyadmin";
            volumes = [
                "/run/mysqld/mysqld.sock:/tmp/mysql.sock"
            ];
            environment = {
                PMA_HOST = "localhost";
                # PMA_ARBITRARY = "1";
            };
            ports = [ "8444:80" ];
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
    systemd.services."container@bot".after = [ "mysql.service" ];
    containers.bot = {
        autoStart = true;
        bindMounts."/run/secrets" = {};
        bindMounts."/run/mysqld/mysqld.sock" = {};
        config = {
            system.stateVersion = "22.05";
            security.pki.certificates = mkForce config.security.pki.certificates;
            documentation.enable = false;
            networking.firewall.enable = false;
            fonts.fonts = with pkgs; [
                jetbrains-mono
                source-han-sans
            ];
            systemd.services.bot = {
                wantedBy = [ "multi-user.target" ];
                environment.SECRETS = config.sops.secrets."bot-secrets.json".path;
                script = ''
                    mkdir -p /var/lib/bot && cd /var/lib/bot
                    ${inputs.cllina.packages.${pkgs.system}.default}/bin/cllina
                '';
            };
        };
    };
}