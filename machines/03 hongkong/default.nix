rec {
    meta = {
        id = "03";
        name = "hongkong";
        address = "hk.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-hongkong-private-key.path;
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-hongkong-private-key.sopsFile = ./secrets.yaml;
        networking.firewall.extraCommands = ''
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8056 -s 172.22.167.96/27 -j nixos-fw-accept
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8056 -s 10.127.20.0/24 -j nixos-fw-accept
        '';
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
        networking.firewall.allowedTCPPorts = [ 80 ];
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
            virtualHosts."tghook.anillc.cn" = {
                locations."/" = {
                    proxyPass = "http://10.127.20.167:8056";
                };
            };
            virtualHosts."tgapi.an.dn42" = {
                listen = [ {
                    addr = "0.0.0.0";
                    port = 8056;
                } ];
                locations."/" = {
                    proxyPass = "https://api.telegram.org";
                };
            };
        };
    };
}