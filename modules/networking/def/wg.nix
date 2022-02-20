{ config, pkgs, lib, ... }: with lib; let
    cfg = config.net.wg;
in {
    options.net.wg = let
        ipOptions = types.submodule ({ ... }: {
            options = {
                addr = mkOption {
                    type = types.str;
                    description = "ip addr";
                };
                peer = mkOption {
                    type = types.nullOr types.str;
                    description = "peer";
                    default = null;
                };
            };
        });
        interfaceOptions = types.submodule {
            options = {
                privateKeyFile = mkOption {
                    type = types.path;
                    description = "private key file";
                    default = config.sops.secrets.wg-private-key.path;
                };
                presharedKeyFile = mkOption {
                    type = types.nullOr types.path;
                    description = "private key file";
                    default = null;
                };
                publicKey = mkOption {
                    type = types.str;
                    description = "public key";
                };
                endpoint = mkOption {
                    type = types.nullOr types.str;
                    description = "endpoint";
                    default = null;
                };
                listen = mkOption {
                    type = types.nullOr types.port;
                    description = "listen port";
                    default = null;
                };
                ip = mkOption {
                    type = types.listOf ipOptions;
                    description = "ip addresses";
                    default = [];
                };
                refresh = mkOption {
                    type = types.int;
                    description = "refresh";
                    default = 0;
                };
            };
        };
    in mkOption {
        type = types.attrsOf interfaceOptions;
        description = "wireguard interfaces";
        default = {};
    };
    config = {
        firewall.publicUDPPorts = builtins.foldl' (acc: x: acc ++ (if x.listen == null then [] else [
            x.listen
        ])) [] (builtins.attrValues cfg);

        net.addresses = let
            addresses = name: value: builtins.foldl' (acc: x: acc ++ [
                { address = x.addr; interface = name; peer = mkIf (x.peer != null) x.peer;  }
            ]) [] value.ip;
        in pkgs.lib.flatten (builtins.attrValues (builtins.mapAttrs addresses cfg));
        
        systemd.services.wireguard-refresh = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            restartIfChanged = true;
            script = ''
                ${pkgs.lib.strings.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: value: ''
                    ${optionalString (value.refresh != 0) ''
                        function wg_${name}() {
                            while :; do
                                sleep ${builtins.toString value.refresh}
                                ${pkgs.wireguard}/bin/wg set ${name} peer ${value.publicKey} endpoint ${value.endpoint}
                                echo the endpoint of ${name} refreshed
                            done
                        }
                        wg_${name} &
                        PIDS[$!]=$!
                    ''}
                '') cfg))}
                wait ''${PIDS[*]}
            '';
        };
    };
}