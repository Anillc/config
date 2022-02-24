rec {
    machines = (import ./..).set;
    meta = {
        id = "03";
        name = "hongkong";
        address = "hk.an.dn42";
        wg-public-key = "FDW5S+3nNS883Q5mKVwym0dwEYKF+nuQ1rPZ+sWVqgc=";
        v4 = "172.22.167.100";
        v6 = "fdc9:83c1:d0ce::4";
        connect = [ machines.shanghai machines.lasvegas machines.de machines.jp ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        # tgapi and deepl
        firewall.internalTCPPorts = [ 8233 ];
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
        virtualisation.oci-containers = {
            backend = "podman";
            containers.deepl = {
                image = "docker.io/zu1k/deepl";
                ports = [ "8233:80" ];
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
            virtualHosts."tghook.anillc.cn" = {
                locations."/" = {
                    proxyPass = "http://172.22.167.99:8056";
                };
            };
        };
        systemd.services.route-chain = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            script = ''
                ${pkgs.route-chain}/bin/route-chain 2602:feda:daf::/96 &
                CHAIN=$!
                sleep 1
                ${pkgs.iproute2}/bin/ip route replace 2602:feda:daf::/48 dev tun0 proto 114 table 114
                wait $CHAIN
            '';
        };
    };
}