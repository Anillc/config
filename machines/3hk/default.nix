lib: rec {
    machines = import ./.. lib;
    meta = {
        id = 3;
        name = "hk";
        address = "hk.an.dn42";
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
        connect = with machines.set; [ sh las de jp ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
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
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            virtualHosts."dav.anillc.cn" = {
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
}