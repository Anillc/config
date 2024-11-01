{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    plugins = with config.services.discourse.package.plugins; [
        discourse-solved discourse-spoiler-alert discourse-math discourse-checklist
        discourse-canned-replies discourse-github discourse-saved-searches
        discourse-yearly-review discourse-docs discourse-reactions
        # discourse-feature-voting discourse-cakeday discourse-follow discourse-footnote
        # discourse-signatures discourse-push-notifications
        # discourse-tooltips discourse-graphviz discourse-automation discourse-bcc
        # discourse-category-experts discourse-characters-required
        # discourse-restricted-replies discourse-templates
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-post-voting";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-post-voting";
                rev = "ff65c9229303b394d89c313be3b00a8cf1b31808";
                sha256 = "sha256-unpJbBNi8KgkpAyyIio9GYe6jgkVyuNIbvOztAkuPZE=";
            };
        })
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-bbcode";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-bbcode";
                rev = "013bf339a2c68e943dcf6db433074eb128019a09";
                sha256 = "sha256-IlXBZPhya0GGMz0ts9SZ+aaYnTNw21Pu54mJS5zsTB0=";
            };
        })
    ];
in {
    services.postgresql.package = pkgs.postgresql_13;
    services.discourse = {
        inherit plugins;
        enable = true;
        hostname = "forum.koishi.xyz";
        admin.skipCreate = true;
        mail = {
            notificationEmailAddress = "noreply@forum.koishi.chat";
            outgoing = {
                serverAddress = "smtp.zeptomail.com";
                port = 587;
                username = "emailapikey";
                passwordFile = config.sops.secrets.discourse-mail.path;
                domain = "forum.koishi.chat";
            };
        };
    };

    services.restic.backups.discourse = {
        initialize = true;
        repository = "rest:http://cola.a:8081/koishi-discourse";
        passwordFile = config.sops.secrets.discourse-restic.path;
        paths = [ "/var/lib/discourse/uploads" "/var/lib/discourse/discourse.psql" ];
        backupPrepareCommand = ''
            export PATH=/run/current-system/sw/bin:$PATH
            PSQL=$(mktemp)
            sudo -u postgres pg_dump discourse > $PSQL
            mv $PSQL /var/lib/discourse/discourse.psql
        '';
        timerConfig = {
            OnCalendar = "daily";
        };
    };

    security.acme.certs = lib.genAttrs [
        "forum.koishi.xyz" "www.koishi.xyz" "koishi.xyz"
    ] (_: { email = "admin@forum.koishi.chat"; });
    cfg.firewall.publicTCPPorts = [ 80 443 ];
    services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts = {
            "koishi.xyz" = {
                enableACME = true;
                forceSSL = true;
                locations."/".return = "302 https://koishi.chat";
            };
            "www.koishi.xyz" = {
                enableACME = true;
                forceSSL = true;
                locations."/".return = "302 https://koishi.chat";
            };
        };
    };
}