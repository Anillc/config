{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.net.wg;
in {
    options.net.wg = let
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
        systemd.services = (listToAttrs (flip mapAttrsToList cfg (name: value: nameValuePair "net-wg-${name}" (let
            configure = ''
                wg set ${name} private-key ${value.privateKeyFile} ${
                    optionalString (value.listen != null) "listen-port ${toString value.listen}"
                }
                wg set ${name} peer "${value.publicKey}" ${
                    optionalString (value.presharedKeyFile != null) ''preshared-key "${value.presharedKeyFile}"''
                } persistent-keepalive 25 allowed-ips 0.0.0.0/0,::/0
                ip link set ${name} up
                ${optionalString (value.endpoint != null) ''
                    wg set ${name} peer "${value.publicKey}" endpoint ${value.endpoint} || true
                ''}
            '';
        in {
            after = [ "network.target" "net-online.service" ];
            before = [ "net.service" ];
            partOf = [ "net-online.service" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [ iproute2 wireguard-tools ];
            reloadIfChanged = true;
            restartTriggers = [ value.endpoint value.publicKey ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
            };
            script = ''
                ip link add ${name} type wireguard
            '' + configure;
            reload = configure;
            postStop = "ip link delete ${name} || true";
        })))) // {
            net.partOf = map (name: "net-wg-${name}.service") (attrNames cfg);
            wireguard-refresh = {
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
    };
}