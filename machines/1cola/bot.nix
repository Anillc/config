{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    bot = inputs.koinix.packages.${pkgs.system}.buildKoishi {
        host = "0.0.0.0";
        port = 8056;
        prefix = "-";
        nickname = "cllina";
        exitCommand = true;
        selfUrl = "https://bot.a";
        plugins = {
            "@chronocat/koishi-plugin-adapter" = {
                endpoint = "http://10.11.1.6:16530";
                token = "\${{ env.CHRONOCAT_TOKEN }}";
            };
            "@chronocat/koishi-plugin-assets-memory" = {};
            adapter-discord.token = "\${{ env.DISCORD_TOKEN }}";
            adapter-telegram = {
                protocol = "polling";
                token = "\${{ env.TELEGRAM_TOKEN }}";
            };
            database-mysql = {
                database = "bot";
                user = "root";
                socketPath = "/run/mysqld/mysqld.sock";
            };
            console = {};
            help = {};
            admin = {};
            chess = {};
            echo = {};
            # forward = {};
            # influxdb-collect = {};
            music = {};
            qrcode = {};
            recall = {};
            schedule = {};
            sudo = {};
            dialogue = {};
            dialogue-author = {};
            dialogue-context = {};
            dialogue-flow = {};
            dialogue-rate-limit = {};
            dialogue-time = {};
            tex = {};
            screenshot = {};
            messages = {};
            puppeteer = {
                executablePath = "${pkgs.chromium}/bin/chromium";
                args = [
                    "--no-sandbox" "--ignore-certificate-errors"
                ];
            };
            assets-local.root = ".koishi/assets";
            glot.apiToken = "\${{ env.GLOT_TOKEN }}";
            verifier = {
                onFriendRequest = 1;
                onGuildMemberRequest = 2;
                onGuildRequest = 3;
            };
            wolfram-alpha.appid = "\${{ env.ALPHA_TOKEN }}";
            translator-youdao = {
                appKey = "\${{ env.YOUDAO_KEY }}";
                secret = "\${{ env.YOUDAO_SECRET }}";
            };
            github = {
                appId = "\${{ env.GITHUB_APPID }}";
                appSecret = "\${{ env.GITHUB_APPSECRET }}";
            };
            "@ifrank/koishi-plugin-xibao" = {};
            "5k" = {};
        };
    };
in {
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
    # systemd.services."container@bot".after = [ "mysql.service" ];
    # containers.bot = {
    #     autoStart = true;
    #     bindMounts."/run/secrets" = {};
    #     bindMounts."/run/mysqld/mysqld.sock" = {};
    #     config = {
    #         system.stateVersion = "22.05";
    #         security.pki.certificates = mkForce config.security.pki.certificates;
    #         documentation.enable = false;
    #         networking.firewall.enable = false;
    #         i18n.defaultLocale = "zh_CN.UTF-8";
    #         fonts.fonts = with pkgs; [
    #             jetbrains-mono
    #             source-han-sans
    #         ];
    #         systemd.services.bot = {
    #             wantedBy = [ "multi-user.target" ];
    #             serviceConfig.EnvironmentFile = config.sops.secrets.bot-secrets.path;
    #             script = ''
    #                 mkdir -p /var/lib/bot && cd /var/lib/bot
    #                 ${bot}/bin/koishi
    #             '';
    #         };
    #     };
    # };
}