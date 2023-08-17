{ config, pkgs, unstable-pkgs, lib, ... }:

with builtins;
with lib;

let
    plugins = with config.services.discourse.package.plugins; [
        discourse-solved discourse-spoiler-alert discourse-math discourse-checklist
        discourse-canned-replies discourse-github discourse-saved-searches
        discourse-yearly-review discourse-docs
        # discourse-feature-voting discourse-cakeday discourse-follow discourse-footnote
        # discourse-signatures discourse-reactions discourse-push-notifications
        # discourse-tooltips discourse-graphviz discourse-automation discourse-bcc
        # discourse-category-experts discourse-characters-required
        # discourse-restricted-replies discourse-templates
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-reactions";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-reactions";
                rev = "5484d64d880ce4ba6fba22446d54195a447cd091";
                sha256 = "sha256-kYqV4ggW6iTWUzHKSYnahKw9VEL9BHZhQ7M+WU3nsyo=";
            };
        })
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-post-voting";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-post-voting";
                rev = "e0fa41dc692b551d562146e4f93120e1e4bdbc5b";
                sha256 = "sha256-BrxFuwk1TFAIXhNOA/tDB8unHXrm+8ATYEL5AIOQ9NI=";
            };
        })
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-bbcode";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-bbcode";
                rev = "eccc17f2763ce2f96c244ed5a96c6118b79c873b";
                sha256 = "sha256-AdKAWIvxDOVN+v4GMFbBBy2uJI5JtuXO9m9z415GBG4=";
            };
        })
    ];
    mapList = list: value: listToAttrs (map (flip nameValuePair value) list);
in {
    services.postgresql.package = pkgs.postgresql_13;
    services.discourse = {
        inherit plugins;
        enable = true;
        package = unstable-pkgs.discourse;
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