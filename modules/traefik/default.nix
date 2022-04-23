{ config, pkgs, lib, ... }: let
    cfg = config.traefik;
in {
    options.traefik = {
        enable = lib.mkEnableOption "enable traefik";
        configFile = lib.mkOption {
            type = lib.types.path;
            description = "";
        };
    };
    config = lib.mkIf cfg.enable {
        firewall.publicTCPPorts = [ 80 443 ];
        system.activationScripts = pkgs.lib.mkAfter {
            traefikConfig = ''
                rm -rf /var/traefik
                mkdir -p /var/traefik
                cp ${cfg.configFile} /var/traefik/config.yaml
                chown -R traefik:traefik /var/traefik
            '';
        };
        services.traefik = {
            enable = true;
            staticConfigOptions = {
                entryPoints = {
                    http = {
                        address = ":80";
                        http.redirections.entryPoint = {
                            to = "https";
                            scheme = "https";
                        };
                    };
                    https = {
                        address = ":443";
                        http.tls.certResolver = "le";
                    };
                };
                certificatesResolvers.le.acme = {
                    email = "acme@anillc.cn";
                    storage = config.services.traefik.dataDir + "/acme.json";
                    tlsChallenge = {};
                };
            };
            dynamicConfigFile = "/var/traefik/config.yaml";
        };
    };
}