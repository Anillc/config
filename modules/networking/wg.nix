
{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    options = {
        wgi = mkOption {
            type = types.listOf (types.submodule ({
                options.name = mkOption {
                    type = types.str;
                    description = "name";
                };
                options.wg-public-key = mkOption {
                    type = types.str;
                    description = "public key";
                };
                options.listen = mkOption {
                    type = types.nullOr types.port;
                    description = "port";
                    default = null;
                };
                options.peer = mkOption {
                    type = types.nullOr types.port;
                    description = "peer port";
                    default = null;
                };
                options.cost = mkOption {
                    type = types.int;
                    description = "ospf cost";
                    default = 65535;
                };
            }));
            description = "internal wireguard interfaces";
            default = [];
        };
    };
    config = {
        # interfaces starts with i will add to ospf
        wg = listToAttrs (map
            (x: nameValuePair "i${x.name}" {
                publicKey = x.wg-public-key;
                listen = mkIf (x ? listen) x.listen;
            }) config.wgi);
        systemd.network.networks = listToAttrs (map (x: nameValuePair "i${x.name}" {
            matchConfig.Name = "i${x.name}";
            # TODO: https://github.com/systemd/systemd/issues/23197
            # addresses = [
            #     { addressConfig = { Address = "fe80::11${toHexString config.meta.id}/64"; }; } # TODO: to 0x1100 + id
            #     # TODO: sid on link for srv6-te
            #     { addressConfig = { Address = "169.254.11.${toString config.meta.id}/24"; Scope = "link"; }; }
            # ];
        }) config.wgi);
        systemd.timers.setup-wireguard = {
            wantedBy = [ "timers.target" ];
            partOf = [ "setup-wireguard.service" ];
            timerConfig = {
                OnCalendar = "*:0";
                Unit = "setup-wireguard.service";
                Persistent = true;
            };
        };
        systemd.services.setup-wireguard = let
            setup = pkgs.writeScript "setup.sh" ''
                #!${pkgs.runtimeShell}
                set -e
                ${concatStringsSep "\n" (map (x: ''
                    ENDPOINT=$(jq -r '.${x.name}' ${config.sops.secrets.endpoints.path})
                    wg set i${x.name} peer "${x.wg-public-key}" endpoint "$ENDPOINT:${toString x.peer}"
                '') (filter (x: x.peer != null) config.wgi))}
            '';
        in {
            wantedBy = [ "multi-user.target" ];
            after = [ "systemd-networkd.service" ];
            before = [ "network-online.target" ];
            partOf = [ "systemd-networkd.service" ];
            path = with pkgs; [ wireguard-tools jq ];
            serviceConfig = {
                Type = "forking";
                ExecStart = pkgs.writeScript "setup-wireguard" ''
                    #!${pkgs.runtimeShell}
                    until ${setup}; do :; done &
                '';
            };
        };
        # TODO: https://github.com/systemd/systemd/issues/23197
        systemd.services.setup-wireguard-linklocal = {
            wantedBy = [ "multi-user.target" ];
            after = [ "systemd-networkd.service" ];
            before = [ "network-online.target" ];
            partOf = [ "systemd-networkd.service" ];
            path = with pkgs; [ iproute2 ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Restart = "on-failure";
            };
            script = concatStringsSep "\n" (map (x: ''
                ip address replace fe80::11${toHexString config.meta.id}/64            dev i${x.name}
                ip address replace 169.254.11.${toString config.meta.id}/24 scope link dev i${x.name}
            '') config.wgi);
            postStop = concatStringsSep "\n" (map (x: ''
                ip address del fe80::11${toHexString config.meta.id}/64 dev i${x.name}
                ip address del 169.254.11.${toString config.meta.id}/24 dev i${x.name}
            '') config.wgi);
        };
    };
}