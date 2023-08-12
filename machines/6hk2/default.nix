rec {
    meta = {
        id = 6;
        name = "hk2";
        wg-public-key = "vj9hsGL/32BbhNuBreUHomdWSUjkuHeuqiCPPYQ+JBk=";
        syncthingId = "RDBLFVV-TR3RNNG-UZ3J3N6-HBDCYV4-EAHYKOC-6ITDHJW-X4UXGJK-7SGK6QX";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.meilisearch = {};
        };
        bgp.enable = true;
        services.meilisearch = {
            enable = true;
            masterKeyEnvironmentFile = config.sops.secrets.meilisearch.path;
        };
        firewall.publicTCPPorts = [ 80 443 ];
        security.acme.certs."search.koishi.chat" = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "admin@forum.koishi.chat";
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            virtualHosts = {
                "search.koishi.chat" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:7700";
                    };
                };
            };
        };
    };
}