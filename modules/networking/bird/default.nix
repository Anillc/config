{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.bgp;
    machines = import ../../../machines lib;
in {
    options.bgp = {
        enable = mkEnableOption "enable bgp";
        upstream = {
            enable = mkEnableOption "enable transit";
            asn = mkOption {
                type = types.str;
                description = "asn";
            };
            address = mkOption {
                type = types.str;
                description = "address";
            };
            password = mkOption {
                type = types.nullOr types.str;
                description = "password";
                default = null;
            };
            multihop = mkOption {
                type = types.bool;
                description = "multihop";
                default = false;
            };
        };
        peers = mkOption {
            type = types.listOf (types.submodule {
                options = {
                    asn = mkOption {
                        type = types.str;
                        description = "asn";
                    };
                    address = mkOption {
                        type = types.str;
                        description = "address";
                    };
                };
            });
            description = "peers";
            default = [];
        };
    };
    config = mkIf cfg.enable {
        # bgp
        firewall.publicTCPPorts = [ 179 ];
        services.bird2 = {
            enable = true;
            checkConfig = false;
            config = ''
                define ASN = 142055;

                router id ${config.meta.v4};
                include "${./utils.conf}";
                protocol device {}
                protocol direct {
                    ipv4;
                    ipv6;
                }
                protocol kernel {
                    learn;
                    ipv4 {
                        import all;
                        export all;
                    };
                }
                protocol kernel {
                    learn;
                    ipv6 {
                        import all;
                        export filter {
                            if net = ::/0 then {
                                krt_prefsrc = 2602:feda:da0::${toHexString config.meta.id};
                            }
                            accept;
                        };
                    };
                }
                ${concatStringsSep "\n" (flip map
                        (filter (x: x.meta.name != config.meta.name) machines.list) (x: ''
                    protocol bgp i${x.meta.name} {
                        graceful restart;
                        local as ASN;
                        neighbor ${x.meta.v6} as ASN;
                        ipv4 {
                            import none;
                            export none;
                        };
                        ipv6 {
                            next hop self ebgp;
                            import filter {
                                bgp_local_pref = 50;
                                accept;
                            };
                            export filter {
                                ${optionalString cfg.upstream.enable ''
                                    if net = ::/0 && source = RTS_INHERIT then {
                                        bgp_path.prepend(${cfg.upstream.asn});
                                        bgp_next_hop = ${config.meta.v6};
                                        accept;
                                    }
                                ''}
                                if source = RTS_BGP then accept;
                                reject;
                            };
                        };
                    }
                ''))}
                ${optionalString cfg.upstream.enable ''
                    protocol bgp transit {
                        graceful restart;
                        local as ASN;
                        neighbor ${cfg.upstream.address} as ${cfg.upstream.asn};
                        ${optionalString cfg.upstream.multihop "multihop;"}
                        ${optionalString (cfg.upstream.password != null) ''password "${cfg.upstream.password}";''}
                        ipv4 {
                            import none;
                            export none;
                        };
                        ipv6 {
                            next hop self;
                            import none;
                            export where source = RTS_STATIC;
                        };
                    }
                ''}


                protocol static {
                    route 2a0e:b107:1170::/48 reject;
                    ipv6;
                }
                protocol static {
                    route 2a0e:b107:1171::/48 reject;
                    ipv6;
                }
                protocol static {
                    route 2a0e:b107:df5::/48 reject;
                    ipv6;
                }
                protocol static {
                    route 2602:feda:da0::/44 reject;
                    ipv6;
                }
                protocol static {
                    route 2a0d:2587:8100::/41 reject;
                    ipv6;
                }
            '';
        };
    };
}