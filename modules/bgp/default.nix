{ pkgs, config, lib, ... }: with lib; let
    cfg = config.bgp;
in {
    imports = [
        ./bird
        ./wireguard
        ./babeld.nix
    ];
    options.bgp = {
        enable = mkEnableOption "enable bgp";
        meta = mkOption {
            type = types.anything;
            description = "";
        };
        connect = mkOption {
            type = types.listOf types.anything;
            default = [];
            description = "";
        };
        extraBirdConfig = mkOption {
            type = types.lines;
            default = "";
            description = "";
        };
        bgpSettings = let
            peer = types.submodule {
                options = {
                    name = mkOption {
                        type = types.str;
                        description = "";
                    };
                    endpoint = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "";
                    };
                    listen = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                        description = "listen port";
                    };
                    v4 = mkOption {
                        type = types.str;
                        description = "peer v4";
                    };
                    publicKey = mkOption {
                        type = types.str;
                        description = "wireguard public key";
                    };
                    presharedKey = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "wireguard preshared key";
                    };
                    asn = mkOption {
                        type = types.str;
                        description = "";
                    };
                    linkLocal = mkOption {
                        type = types.str;
                        description = "peer link local address";
                    };
                };
            };
        in {
            dn42 = {
                v4 = mkOption {
                    type = types.str;
                    description = "";
                };
                v6 = mkOption {
                    type = types.str;
                    description = "";
                };
                peers = mkOption {
                    type = types.listOf peer;
                    default = [];
                    description = "";
                };
            };
            internet = {
                peers = mkOption {
                    type = types.listOf peer;
                    default = [];
                    description = "";
                };
            };
        };
        bgpTransit = {
            enable = mkEnableOption "enable internet transit";
            asn = mkOption {
                type = types.str;
                description = "transit asn";
            };
            address = mkOption {
                type = types.str;
                description = "transit address";
            };
            password = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "bgp password";
            };
        };
    };
    config = mkIf cfg.enable {
        boot.kernel.sysctl = lib.mkForce {
            "net.ipv4.ip_forward" = 1;
            "net.ipv6.conf.all.forwarding" = 1;
            "net.ipv4.conf.all.rp_filter" = 0;
        };
        services.cron.enable = true;
        systemd.services.dummy = let
            start = ''
                export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
                    iproute2
                ]}
                ip link add dummy2526 type dummy
                ip link set dummy2526 up
                ip addr add 2602:feda:da0::${cfg.meta.id}/128 dev dummy2526
                ip addr add ${cfg.bgpSettings.dn42.v4}/32 dev dummy2526
                ip addr add ${cfg.bgpSettings.dn42.v6}/128 dev dummy2526
                
                ip route add 2602:feda:da0::${cfg.meta.id}/128 dev dummy2526 proto 114 table 114
                ip route add ${cfg.bgpSettings.dn42.v4}/32 dev dummy2526 proto 114 table 114
                ip route add ${cfg.bgpSettings.dn42.v6}/128 dev dummy2526 proto 114 table 114
                ip rule add table 114
            '';
            stop = ''
                export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
                    iproute2
                ]}
                ip rule del table 114
                ip route flush table 114
                ip link del dummy2526
            '';
        in {
            description = "dummy interface";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = start;
            preStop = stop;
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = "yes";
            };
        };
    };
}