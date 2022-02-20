{ config, pkgs, lib, ... }: with lib; let
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
    config = {
        systemd.services.net = {
            after = [ "network.target" ];
            wantedBy = [ "network-online.target" ];
            path = with pkgs; [ iproute2 wireguard-tools];
            restartIfChanged = true;
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
            };
            script = let
                wgInterfaces = text: builtins.foldl' (acc: x: acc + ''
                    ${text x}
                '') "" (builtins.attrValues (builtins.mapAttrs (name: value: {
                    inherit name;
                } // value) cfg.wg));
            in ''
                ip link add dummy2526 type dummy
                ip link set dummy2526 up

                ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                    ip link set ${x} up
                '') cfg.up)}

                ${pkgs.lib.strings.concatStrings (builtins.attrValues (builtins.mapAttrs (name: value: ''
                    ip link add ${name} type bridge
                    ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                        ip link set ${x} master ${name}
                    '') value)}
                    ip link set ${name} up
                '') cfg.bridges))}
                
                ${wgInterfaces (x: ''
                    ip link add ${x.name} type wireguard
                    wg set ${x.name} private-key ${x.privateKeyFile} ${
                        optionalString (x.listen != null) "listen-port ${builtins.toString x.listen}"
                    }
                    wg set ${x.name} peer "${x.publicKey}" ${
                        optionalString (x.presharedKeyFile != null) "preshared-key \"${x.presharedKeyFile}\""
                    } persistent-keepalive 25 allowed-ips 0.0.0.0/0,::/0
                    ip link set ${x.name} up
                '')}

                ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                    ip address add ${x.address} dev ${x.interface} ${
                        optionalString (x.peer != null) "peer ${x.peer}"
                    } || true
                '') cfg.addresses)}

                ${optionalString (cfg.gateway4 != null) ''
                    ip route replace default via ${cfg.gateway4}
                ''}
                ${optionalString (cfg.gateway6 != null) ''
                    ip route replace default via ${cfg.gateway6}
                ''}

                # set endpoint after set default gateway
                ${wgInterfaces (x: ''
                    ${optionalString (x.endpoint != null) ''
                        wg set ${x.name} peer "${x.publicKey}" endpoint ${x.endpoint} || true
                    ''}
                '')}

                ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                    ip route replace ${x.dst} ${
                        optionalString (x.src != null) "src ${x.src}"
                    } ${
                        optionalString (x.interface != null) "dev ${x.interface}"
                    } ${
                        optionalString (x.gateway != null) "via ${x.gateway}"
                    } ${
                        optionalString (x.proto != null) "proto ${builtins.toString x.proto}"
                    } ${
                        optionalString (x.table != null) "table ${builtins.toString x.table}"
                    } ${
                        optionalString x.onlink "onlink"
                    }
                '') cfg.routes)}

                ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                    ip -4 rule add table ${builtins.toString x}
                    ip -6 rule add table ${builtins.toString x}
                '') cfg.tables)}
            '';
            postStop = ''
                ${pkgs.lib.strings.concatStrings (builtins.map (x: ''
                    ip -4 rule delete table ${builtins.toString x} || true
                    ip -6 rule delete table ${builtins.toString x} || true
                '') cfg.tables)}

                ip link delete dummy2526 || true
            '' + pkgs.lib.strings.concatStringsSep "\n" (
                (builtins.map (x: "ip link delete ${x} || true") (builtins.attrNames cfg.wg))
                ++ (builtins.map (x: "ip link delete ${x} || true") (builtins.attrNames cfg.bridges))
            );
        };
    };
}