{ config, pkgs, lib, inputs, ... }:

with lib;
with builtins;

{
    firewall.extraPostroutingFilterRules = ''
        meta iifname sso meta oifname "en*" meta mark set 0x114
    '';
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.11.1.8/32 via "sso";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    ids.uids.zitadel = 423;
    ids.gids.zitadel = 423;
    users.users.zitadel = {
        isSystemUser = true;
        group = "zitadel";
        uid = config.ids.uids.zitadel;
    };
    users.groups.zitadel.gid = config.ids.gids.zitadel;
    systemd.services."container@sso".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    };
    containers.sso = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.sso = {};
        bindMounts."/run/secrets" = {};
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        config = c: {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.sso.ipv4.addresses = [{ address = "10.11.1.8"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "sso"; };
            ids.uids.zitadel = 423;
            ids.gids.zitadel = 423;
            users.users.zitadel.uid = c.config.ids.uids.zitadel;
            users.groups.zitadel.gid = c.config.ids.gids.zitadel;
            systemd.services.zitadel.after = [ "postgresql.service" ];
            services.zitadel = {
                enable = true;
                masterKeyFile = config.sops.secrets.zitadel.path;
                settings = {
                    ExternalDomain = "sso.anil.lc";
                    ExternalPort = 443;
                    ExternalSecure = true;
                    Database.postgres = {
                        Host = "localhost";
                        Port = 5432;
                        Database = "zitadel";
                        User = {
                            Username = "zitadel";
                            Passowrd = "zitadel";
                            SSL.Mode = "disable";
                        };
                        Admin = {
                            Username = "admin";
                            Passowrd = "admin";
                            SSL.Mode = "disable";
                        };
                    };
                };
                steps.FirstInstance.Org.Human.UserName = "Anillc";
            };
            services.postgresql = {
                enable = true;
                enableTCPIP = true;
                authentication = ''
                  #type database DBuser origin-address auth-method
                  host  all      all    127.0.0.1/32  trust
                  host  all      all    ::1/128       trust
                '';
                ensureUsers = [ { name = "admin"; ensureClauses.superuser = true; } ];
            };
        };
    };
}