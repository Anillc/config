rec {
    meta = {
        id = 4;
        name = "koishi";
        wg-public-key = "++8g+U89u77H0EbWI81j20CKKeSp7eY847M30sI2XFg=";
        syncthingId = "44JIF3B-D3EIAAE-F36UOOA-PM5CMFP-X2VZNQ3-5ZPPMCI-CIQDINJ-J5TRVQL";
        # enable = false;
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
                discourse-admin = {
                    owner = "discourse";
                    group = "discourse";
                };
                discourse-mail = {
                    owner = "discourse";
                    group = "discourse";
                };
            };
        };
        bgp.enable = true;

        services.postgresql.package = pkgs.postgresql_13;
        services.discourse = {
            enable = true;
            hostname = "forum.koishi.xyz";
            admin = {
                username = "Koishi";
                fullName = "Koishi";
                email = "admin@forum.koishi.chat";
                passwordFile = config.sops.secrets.discourse-admin.path;
            };
            mail.outgoing = {
                serverAddress = "smtp.zeptomail.com";
                port = 587;
                forceTLS = true;
                authentication = "login";
                username = "emailapikey";
                passwordFile = config.sops.secrets.discourse-mail.path;
                domain = "forum.koishi.chat";
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
    };
}
