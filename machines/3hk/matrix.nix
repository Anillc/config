{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    services.postgresql = {
        enable = true;
        initialScript = pkgs.writeText "synapse-init.sql" ''
            CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
            CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
                TEMPLATE template0
                LC_COLLATE = "C"
                LC_CTYPE = "C";
        '';
    };
    services.matrix-synapse = {
        enable = true;
        server_name = "matrix.anillc.cn";
        listeners = [{
            port = 8008;
            bind_address = "127.0.0.1";
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [{
                names = [ "client" "federation" ];
                compress = false;
            }];
        }];
    };
    services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        virtualHosts = {
            "matrix.anillc.cn" = {
                enableACME = true;
                forceSSL = true;
                locations."= /.well-known/matrix/server".extraConfig = ''
                    add_header Content-Type application/json;
                    return 200 '{"m.server": "matrix.anillc.cn:443"}';
                '';
                locations."/".extraConfig = ''
                    return 404;
                '';
                locations."/_matrix" = {
                    proxyPass = "http://127.0.0.1:8008";
                    extraConfig = ''
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_set_header X-Forwarded-Host $host;
                        proxy_set_header X-Forwarded-Server $host;
                    '';
                };
            };
        };
    };
}