{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    bot = inputs.koinix.lib.${pkgs.system}.buildKoishi {
        host = "0.0.0.0";
        port = 8056;
        prefix = "-";
        nickname = "cllina";
        exitCommand = true;
        selfUrl = "https://bot.a";
        plugins = {
            adapter-satori = {
                endpoint = "http://127.0.0.1:5500";
                token = "\${{ env.CHRONOCAT_TOKEN }}";
            };
            # adapter-discord.token = "\${{ env.DISCORD_TOKEN }}";
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
            "@ifrank/koishi-plugin-xibao" = {};
            "5k" = {};
        };
    };
    wxhelper = (inputs.flake-parts.lib.evalFlakeModule {
        inherit inputs;
        specialArgs = { inherit pkgs; };
    } {
        imports = [ inputs.wxhelper-nix.flakeModules.default ];
        wxhelper = {
            port = 5901;
            display = 115;
        };
    }).config.wxhelper.wxhelper;
in {
    systemd.tmpfiles.rules = [
        "d /var/lib/chronocat 0700 root root"
        "d /var/lib/wxhelper  0700 root root"
    ];
    systemd.services.chronocat = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            WorkingDirectory = "/var/lib/chronocat";
            ExecStart = "${inputs.chronocat-nix.packages.x86_64-linux.default}/bin/chronocat";
        };
    };
    systemd.services.wxhelper = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            WorkingDirectory = "/var/lib/wxhelper";
            ExecStart = "${wxhelper}/bin/wxhelper";
        };
    };

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
            i18n.defaultLocale = "zh_CN.UTF-8";
            fonts.packages = with pkgs; [
                jetbrains-mono
                source-han-sans
            ];
            systemd.tmpfiles.rules = [ "d /var/lib/bot 0700 root root" ];
            systemd.services.bot = {
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                    EnvironmentFile = config.sops.secrets.bot-secrets.path;
                    ExecStart = "${bot}/bin/koishi";
                };
            };
        };
    };
}