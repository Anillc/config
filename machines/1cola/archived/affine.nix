{ config, pkgs, lib, inputs, ... }:

with lib;
with builtins;

{
    cfg.firewall.extraPostroutingFilterRules = ''
        meta iifname affine meta oifname "en*" meta mark set 0x114
    '';
    services.bird2.config = ''
        protocol static {
            route 10.11.1.7/32 via "affine";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    systemd.services."container@affine".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    };
    containers.affine = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.affine = {};
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        config = {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.affine.ipv4.addresses = [{ address = "10.11.1.7"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.cfg.meta.v4; interface = "affine"; };
            services.redis.servers.affine.enable = true;
            services.postgresql = {
                enable = true;
                enableTCPIP = true;
                authentication = ''
                  #type database DBuser origin-address auth-method
                  host  all      all    127.0.0.1/32  trust
                  host  all      all    ::1/128       trust
                '';
                initialScript = pkgs.writeText "affine-init.sql" ''
                    CREATE ROLE "affine" WITH LOGIN PASSWORD 'affine';
                    CREATE DATABASE "affine" WITH OWNER "affine";
                '';
            };
            virtualisation.oci-containers = {
                backend = "podman";
                containers.affine = {
                    image = "ghcr.io/toeverything/affine-graphql:stable";
                    extraOptions = [ "--network=host" ];
                    cmd = [ "sh" "-c" "node ./scripts/self-host-predeploy && node ./dist/index.js" ];
                    volumes = [
                        "affine-config:/root/.affine/config"
                        "affine-storage:/root/.affine/storage"
                    ];
                    environment = {
                        NODE_OPTIONS = "--import=./scripts/register.js";
                        AFFINE_CONFIG_PATH = "/root/.affine/config";
                        REDIS_SERVER_HOST = "127.0.0.1";
                        DATABASE_URL = "postgres://affine:affine@127.0.0.1:5432/affine";
                        NODE_ENV = "production";
                        AFFINE_ADMIN_EMAIL = "admin@anil.lc";
                        AFFINE_ADMIN_PASSWORD = "p@ssword";
                    };
                };
            };
        };
    };
}