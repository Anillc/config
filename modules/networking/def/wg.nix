{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.wg;
in {
    options.wg = let
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
        firewall.publicUDPPorts = map (x: x.listen) (filter (x: x.listen != null) (attrValues cfg));
        systemd.network.netdevs = mapAttrs (name: value: {
            netdevConfig = {
                Name = name;
                Kind = "wireguard";
            };
            wireguardConfig = {
                PrivateKeyFile = value.privateKeyFile;
                ListenPort = mkIf (value.listen != null) value.listen;
            };
            wireguardPeers = [{
                wireguardPeerConfig = {
                    PublicKey = value.publicKey;
                    PresharedKeyFile = mkIf (value.presharedKeyFile != null) value.privateKeyFile;
                    Endpoint = mkIf (value.endpoint != null) value.endpoint;
                    PersistentKeepalive = 25;
                    AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                };
            }];
        }) cfg;
        systemd.services.wireguard-refresh = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            restartIfChanged = true;
            path = with pkgs; [ wireguard-tools ];
            script = ''
                ${concatStringsSep "\n" (mapAttrsToList (name: value: ''
                    ${optionalString (value.refresh != 0) ''
                        function wg_${name}() {
                            while :; do
                                sleep ${toString value.refresh}
                                wg set ${name} peer ${value.publicKey} endpoint ${value.endpoint} || true
                            done
                        }
                        wg_${name} &
                    ''}
                '') cfg)}
                wait
            '';
        };
    };
}