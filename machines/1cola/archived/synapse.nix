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
            server_name = "m.anil.lc";
            public_baseurl = "https://m.anil.lc";
            # app_service_config_files = [ "/var/lib/matrix-synapse/cllina.yaml" ];
            # enable_registration = true;
            # enable_registration_without_verification = true;
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
# "m.anil.lc" = {
#     enableACME = true;
#     forceSSL = true;
#     locations."/".extraConfig = "return 404;";
#     locations."/_matrix".proxyPass = "http://cola.a:8008";
#     locations."/_synapse/client".proxyPass = "http://cola.a:8008";
#     locations."= /.well-known/matrix/server".extraConfig = ''
#         return 200 '{ "m.server": "m.anil.lc:443" }';
#     '';
#     locations."= /.well-known/matrix/client".extraConfig = ''
#         return 200 '{ "m.homeserver": { "base_url": "https://m.anil.lc" } }';
#     '';
# };