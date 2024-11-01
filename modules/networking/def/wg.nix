{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.cfg.wg;
in {
    options.cfg.wg = let
        interfaceOptions = types.submodule {
            options = {
                privateKeyFile = mkOption {
                    type = types.path;
                    description = "private key file";
                    default = config.sops.secrets.wg-private-key.path;
                };
                publicKey = mkOption {
                    type = types.str;
                    description = "public key";
                };
                endpoint = mkOption {
                    type = types.str;
                    description = "endpoint";
                };
                listen = mkOption {
                    type = types.port;
                    description = "listen port";
                };
                mtu = mkOption {
                    type = types.int;
                    description = "mtu";
                    default = 1420;
                };
            };
        };
    in mkOption {
        type = types.attrsOf interfaceOptions;
        description = "wireguard interfaces";
        default = {};
    };
    config = {
        systemd.network.netdevs = mapAttrs (name: value: {
            netdevConfig = {
                Name = name;
                Kind = "wireguard";
                MTUBytes = toString value.mtu;
            };
            wireguardConfig = {
                PrivateKeyFile = value.privateKeyFile;
                ListenPort = value.listen;
            };
            wireguardPeers = [{
                wireguardPeerConfig = {
                    PublicKey = value.publicKey;
                    Endpoint = value.endpoint;
                    PersistentKeepalive = 25;
                    AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                };
            }];
        }) cfg;
    };
}