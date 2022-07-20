rec {
    meta = {
        id = 3;
        name = "hk";
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.vaultwarden = {};
        };
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "38008";
                address = "2406:4440::1";
            };
            peers.aperix = { # APERIX
                asn = "38008";
                address = "2406:4440::100";
            };
        };
        services.webdav = {
            enable = true;
            settings = {
                address = "127.0.0.1";
                port = 8081;
                scope = "/var/dav";
                auth = true;
                users = [{
                    username = "Anillc";
                    password = "{bcrypt}$2a$10$xP5yTZsZvRcyOKdRHSpmyOD1.jupaU5gCiXwDY7/TYInIDZoqPl62";
                    modify = true;
                }];
            };
        };
        services.vaultwarden = {
            enable = true;
            environmentFile = config.sops.secrets.vaultwarden.path;
            config = {
                DOMAIN = "https://vw.anillc.cn";
                SIGNUPS_ALLOWED = false;
            };
        };
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            virtualHosts = {
                "vw.anillc.cn" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8000";
                    };
                };
                "dav.anillc.cn" = {
                    locations."/" = {
                        proxyPass = "http://127.0.0.1:8081";
                        extraConfig = ''
                            add_header Access-Control-Allow-Origin "*" always;
                            add_header Access-Control-Allow-Methods "PROPFIND, COPY, MOVE, MKCOL, CONNECT, DELETE, DONE, GET, HEAD, OPTIONS, PATCH, POST, PUT" always;
                            add_header Access-Control-Allow-Headers "Authorization, Origin, X-Requested-With, Content-Type, Accept, DNT, X-CustomHeader, Keep-Alive,User-Agent, X-Requested-With, If-Modified-Since, Cache-Control, Content-Range, Range, Depth" always;
                            if ($request_method = "OPTIONS") {
                                return 204;
                            }
                            proxy_set_header X-Real-IP $remote_addr;
                            proxy_set_header REMOTE-HOST $remote_addr;
                            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                            proxy_set_header Host $host;
                            proxy_redirect off;
                        '';
                    };
                };
            };
        };
    };
}