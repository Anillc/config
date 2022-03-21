{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.net;
in {
    options.net = {
        addresses = mkOption {
            type = types.listOf (types.submodule {
                options.interface = mkOption {
                    type = types.str;
                    description = "interface";
                };
                options.address = mkOption {
                    type = types.str;
                    description = "address";
                };
                options.peer = mkOption {
                    type = types.nullOr types.str;
                    description = "peer";
                    default = null;
                };
            });
            description = "addresses";
            default = [];
        };
        routes = mkOption {
            type = types.listOf (types.submodule {
                options.dst = mkOption {
                    type = types.str;
                    description = "dst";
                };
                options.src = mkOption {
                    type = types.nullOr types.str;
                    description = "src";
                    default = null;
                };
                options.interface = mkOption {
                    type = types.nullOr types.str;
                    description = "interface";
                    default = null;
                };
                options.gateway = mkOption {
                    type = types.nullOr types.str;
                    description = "gateway";
                    default = null;
                };
                options.proto = mkOption {
                    type = types.nullOr types.int;
                    description = "proto";
                    default = null;
                };
                options.table = mkOption {
                    type = types.nullOr types.int;
                    description = "table";
                    default = null;
                };
                options.onlink = mkOption {
                    type = types.bool;
                    description = "onlink";
                    default = false;
                };
            });
            description = "routes";
            default = [];
        };
        bridges = mkOption {
            type = types.attrsOf (types.listOf types.str);
            description = "bridge";
            default = {};
        };
        up = mkOption {
            type = types.listOf types.str;
            description = "up interfaces";
            default = [];
        };
        tables = mkOption {
            type = types.listOf types.int;
            description = "tables";
            default = [];
        };
        gateway4 = mkOption {
            type = types.nullOr types.str;
            description = "gateway4";
            default = null;
        };
        gateway6 = mkOption {
            type = types.nullOr types.str;
            description = "gateway6";
            default = null;
        };
    };
    config = let
        configureNetwork = ''
            ${concatStrings (map (x: ''
                ip address add ${x.address} dev ${x.interface} ${
                    optionalString (x.peer != null) "peer ${x.peer}"
                } || true
            '') cfg.addresses)}
            ${concatStrings (map (x: ''
                ip route replace ${x.dst} ${
                    optionalString (x.src != null) "src ${x.src}"
                } ${
                    optionalString (x.interface != null) "dev ${x.interface}"
                } ${
                    optionalString (x.gateway != null) "via ${x.gateway}"
                } ${
                    optionalString (x.proto != null) "proto ${toString x.proto}"
                } ${
                    optionalString (x.table != null) "table ${toString x.table}"
                } ${
                    optionalString x.onlink "onlink"
                } || true
            '') cfg.routes)}
            ${optionalString (cfg.gateway4 != null) ''
                ip route replace default via ${cfg.gateway4} || true
            ''}
            ${optionalString (cfg.gateway6 != null) ''
                ip route replace default via ${cfg.gateway6} || true
            ''}
        '';
        stopNetwork = concatStringsSep "\n" (flatten [
            (map (x: "ip route del ${x.dst} ${
                optionalString (x.table != null) "table ${toString x.table}"
            } || true") cfg.routes)
            (map (x: "ip address del ${x.address} dev ${x.interface} || true") cfg.addresses)
        ]);
    in {
        systemd.services.net-online = {
            after = [ "network.target" ];
            wantedBy = [ "network-online.target" ];
            restartIfChanged = true;
            path = with pkgs; [ iproute2 ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
            };
            script = ''
                ip link add dmy11 type dummy
                ip link set dmy11 up
                ${concatStrings (map (link: ''
                    ip link set ${link} up
                '') cfg.up)}
                ${concatStrings (mapAttrsToList (name: value: ''
                    ip link add ${name} type bridge
                    ${concatStrings (map (x: ''
                        ip link set ${x} master ${name}
                    '') value)}
                    ip link set ${name} up
                '') cfg.bridges)}
                ${configureNetwork}
                ${concatStrings (map (x: ''
                    ip -4 rule add table ${toString x}
                    ip -6 rule add table ${toString x}
                '') cfg.tables)}
            '';
            postStop = concatStringsSep "\n" (flatten [
                (map (x: ''
                    ip -4 rule delete table ${toString x} || true
                    ip -6 rule delete table ${toString x} || true
                '') cfg.tables)
                stopNetwork
                (map (x: "ip link del ${x} || true") (attrNames cfg.bridges))
                "ip link del dmy11"
            ]);
        };
        systemd.services.net = {
            after = [ "net-online.target" ];
            wantedBy = [ "multi-user.target" ];
            restartIfChanged = true;
            path = with pkgs; [ iproute2 ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Restart = "on-failure";
            };
            script = configureNetwork;
            postStop = stopNetwork;
        };
    };
}