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
        withJemalloc = true;
        settings = {
            server_name = "matrix.anillc.cn";
            public_baseurl = "https://matrix.anillc.cn";
            # app_service_config_files = [ "/var/lib/matrix-synapse/cllina.yaml" ];
            listeners = [{
                port = 8008;
                bind_addresses = [ "0.0.0.0" ];
                type = "http";
                tls = false;
                x_forwarded = true;
                resources = [{
                    names = [ "client" "federation" ];
                    compress = true;
                }];
            }];
        };
    };
}