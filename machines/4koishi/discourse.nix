{ config, pkgs, unstable-pkgs, lib, ... }:

with builtins;
with lib;

let
    plugins = with config.services.discourse.package.plugins; [
        discourse-solved discourse-spoiler-alert discourse-math discourse-checklist
        discourse-canned-replies discourse-github discourse-saved-searches
        discourse-yearly-review
        # discourse-feature-voting discourse-cakeday discourse-follow discourse-footnote
        # discourse-signatures discourse-reactions discourse-push-notifications
        # discourse-tooltips discourse-graphviz discourse-automation discourse-bcc
        # discourse-upvotes discourse-category-experts discourse-characters-required
        # discourse-restricted-replies discourse-templates
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-reactions";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-reactions";
                rev = "8bdbc4af68ddaced74b66aaf4046236ce3ff713c";
                sha256 = "sha256-L9R+YD6BiZeZ53hxJGo3LBKjPajM7CmGbFrnRzIFUCA=";
            };
        })
        (config.services.discourse.package.mkDiscoursePlugin {
            name = "discourse-upvotes";
            src = pkgs.fetchFromGitHub {
                owner = "discourse";
                repo = "discourse-upvotes";
                rev = "c3527defe2abb18907b58eec110b42b0bc911447";
                sha256 = "sha256-n6xBMzYq4BVFxnYtIaN0jBwf6MUl31NaZR8N220gQYw=";
            };
        })
    ];
in {
    services.postgresql.package = pkgs.postgresql_13;
    services.discourse = {
        inherit plugins;
        enable = true;
        package = unstable-pkgs.discourse;
        hostname = "forum.koishi.xyz";
        admin = {
            username = "Koishi";
            fullName = "Koishi";
            email = "admin@forum.koishi.chat";
            passwordFile = config.sops.secrets.discourse-admin.path;
        };
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

    security.acme.certs."forum.koishi.xyz" = {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = "admin@forum.koishi.chat";
    };
    firewall.publicTCPPorts = [ 80 443 ];
    services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
    };
}