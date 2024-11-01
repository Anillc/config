
{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    options = {
        cfg.wgi = mkOption {
            type = types.listOf (types.submodule ({
                options.id = mkOption {
                    type = types.int;
                    description = "id";
                };
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
    config = let
        mapWgi = f: map (x: f {
            inherit x;
            # interfaces starts with i will be added to ospf
            interface = "i${x.name}";
            # real ports start from 11000
            uClient = 11100 + x.id;
            uServer = 11200 + x.id;
        }) config.cfg.wgi;
    in {
        systemd.services.wg-udp2raw = {
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig.Restart = "always";
            path = with pkgs; [ jq udp2raw dig ];
            script = mkMerge ((mapWgi ({ x, uClient, uServer, ... }: ''
                ENDPOINT=$(jq -r '.${x.name}' ${config.sops.secrets.endpoints.path})
                IP=$(dig +short $ENDPOINT | tail -n1)
                ${optionalString (x.listen != null) ''
                    udp2raw -s -l0.0.0.0:${toString x.listen} -r127.0.0.1:${toString uServer} --raw-mode faketcp &
                ''}
                ${optionalString (x.peer != null) ''
                    udp2raw -c -l0.0.0.0:${toString uClient} -r$IP:${toString x.peer} --raw-mode faketcp &
                ''}
            '')) ++ [ ''
                wait
            '' ]);
        };
        systemd.network.networks = mkMerge (mapWgi ({ interface, ... }: {
            "${interface}" = {
                matchConfig.Name = interface;
                addresses = [
                    { addressConfig = { Address = "fe80::11${toHexString config.cfg.meta.id}/64"; }; } # TODO: to 0x1100 + id
                    { addressConfig = { Address = "169.254.11.${toString config.cfg.meta.id}/24"; Scope = "link"; }; }
                ];
            };
        }));
        cfg.wg = mkMerge (mapWgi ({ x, interface, uClient, uServer, ... }: {
            "${interface}" = {
                publicKey = x.wg-public-key;
                endpoint = "127.0.0.1:${toString uClient}";
                listen = uServer;
                mtu = 1280;
            };
        }));
        cfg.firewall.extraOutRules = mkMerge (mapWgi ({ x, ... }: ''
            ${optionalString (x.listen != null) "tcp sport ${toString x.listen} tcp flags rst drop"}
            ${optionalString (x.peer != null)   "tcp dport ${toString x.peer}   tcp flags rst drop"}
        ''));
    };
}