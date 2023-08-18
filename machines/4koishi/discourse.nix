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
                rev = "97d468c46905ee8c715710ffa224e5c6eb763770";
                sha256 = "sha256-7nV8xYPh5op4QiLT6GWLsTshAEmV3uZGVsksDfO2was=";
            };
        })
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-bbcode";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-bbcode";
                rev = "a3641edffafbb232ead9711cc84c6dc7bee052f4";
                sha256 = "sha256-2arfeL6osnG+wSB+vCqQmOIx6+MbcUhWBiSbDZ1MveM=";
            };
        })
    ];
    mapList = list: value: listToAttrs (map (flip nameValuePair value) list);
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
        repository = "rest:https://restic.a/koishi-discourse";
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

    security.acme.certs = mapList [ "forum.koishi.xyz" "www.koishi.xyz" "koishi.xyz" ] {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = "admin@forum.koishi.chat";
    };
    firewall.publicTCPPorts = [ 80 443 ];
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