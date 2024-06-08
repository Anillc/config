{ config, pkgs, lib, inputs, ... }:

with lib;
with builtins;

let
    yaml = (pkgs.formats.yaml {}).generate;
    firefish-config = yaml "firefish-config" {
        url = "https://ff.ci";
        port = 3000;
        db = {
            host = "localhost";
            port = 5432;
            db = "firefish";
            user = "firefish";
            pass = "firefish";
        };
        redis = {
            host = "localhost";
            port = 6379;
        };
        reservedUsernames = [ "root" "admin" "administrator" "me" "system" ];
    };
in {
    firewall.extraPostroutingFilterRules = ''
        meta iifname firefish meta oifname "en*" meta mark set 0x114
    '';
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.11.1.9/32 via "firefish";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    systemd.services."container@firefish".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    };
    containers.firefish = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.firefish = {};
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        config = {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.firefish.ipv4.addresses = [{ address = "10.11.1.9"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "firefish"; };
            services.postgresql = {
                enable = true;
                enableTCPIP = true;
                extraPlugins = p: with p; [ pgroonga ];
                ensureDatabases = [ "firefish" ];
                ensureUsers = [ { name = "firefish"; ensureDBOwnership = true; } ];
                authentication = ''
                    #type database DBuser   origin-address auth-method
                    host  all      firefish 127.0.0.1/32   trust
                    host  all      firefish ::1/128        trust
                    local all      firefish                trust
                '';
                initialScript = pkgs.writeText "pgroonga" ''
                    CREATE USER "firefish";
                    CREATE DATABASE "firefish" WITH OWNER "firefish";
                    \c firefish;
                    CREATE EXTENSION pgroonga;
                '';
            };
            services.redis.servers.firefish = {
                enable = true;
                port = 6379;
            };
            virtualisation.oci-containers = {
                backend = "podman";
                containers.firefish = {
                    image = "registry.firefish.dev/firefish/firefish";
                    extraOptions = [ "--network=host" ];
                    volumes = [
                        "firefish-files:/firefish/files"
                        "${firefish-config}:/firefish/.config/default.yml"
                    ];
                };
            };
        };
    };
}