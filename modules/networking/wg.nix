
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
            addresses = [
                { addressConfig = { Address = "fe80::11${toHexString config.meta.id}/64"; }; }
                { addressConfig = { Address = "169.254.11.${toString config.meta.id}/24"; Scope = "link"; }; }
            ];
        }) config.wgi);
        systemd.services.setup-wireguard = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" "systemd-networkd.service" ];
            partOf = [ "systemd-networkd.service" ];
            path = with pkgs; [ wireguard-tools jq ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Restart = "on-failure";
            };
            script = concatStringsSep "\n" (map (x: ''
                ENDPOINT=$(jq -r '.${x.name}' ${config.sops.secrets.endpoints.path})
                wg set i${x.name} peer "${x.wg-public-key}" endpoint "$ENDPOINT:${toString x.peer}"
            '') (filter (x: x.peer != null) config.wgi));
        };
    };
}