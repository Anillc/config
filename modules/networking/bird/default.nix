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
            type = types.attrsOf (types.submodule {
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
            default = {};
        };
        extraBirdConfig = mkOption {
            type = types.lines;
            description = "extraBirdConfig";
            default = "";
        };
    };
    config = mkIf cfg.enable {
        # bgp
        firewall.publicTCPPorts = [ 179 ];
        firewall.publicUDPPorts = [ 3784 ];
        firewall.extraInputRules = "ip6 daddr ff02::5/128 accept";
        services.bird2 = {
            enable = true;
            checkConfig = false;
            config = ''
                define ASN = 142055;

                router id ${config.meta.v4};
                include "${./utils.conf}";

                ipv4 table igp_v4;
                ipv6 table igp_v6;
                ipv6 table bgp_v6;

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
                            if net = ::/0 || net ~ [2000::/3+] then {
                                krt_prefsrc = ${config.meta.externalV6};
                            }
                            accept;
                        };
                    };
                }
                protocol pipe {
                    table igp_v4;
                    peer table master4;
                    import none;
                    export all;
                }
                protocol pipe {
                    table igp_v6;
                    peer table master6;
                    import none;
                    export all;
                }
                protocol pipe {
                    table bgp_v6;
                    peer table master6;
                    import none;
                    export filter {
                        ${optionalString cfg.upstream.enable ''
                            if net = ::/0 then {
                                reject;
                            }
                        ''}
                        accept;
                    };
                }
                protocol bfd {
                    accept direct;
                    interface "i*";
                }
                protocol ospf v3 {
                    ipv4 {
                        table igp_v4;
                        import filter {
                            krt_prefsrc = ${config.meta.v4};
                            accept;
                        };
                        export where source = RTS_STATIC;
                    };
                    area 0 {
                        ${concatStringsSep "\n" (flip map (config.wgi) (x: ''
                            interface "i${x.name}" {
                                bfd;
                                cost ${toString x.cost};
                            };
                        ''))}
                    };
                }
                protocol ospf v3 {
                    ipv6 {
                        table igp_v6;
                        import filter {
                            krt_prefsrc = ${config.meta.v6};
                            accept;
                        };
                        export where source = RTS_STATIC;
                    };
                    area 0 {
                        ${concatStringsSep "\n" (flip map (config.wgi) (x: ''
                            interface "i${x.name}" {
                                bfd;
                                cost ${toString x.cost};
                            };
                        ''))}
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
                            table bgp_v6;
                            igp table master6;
                            next hop self ebgp;
                            import filter {
                                bgp_local_pref = 50;
                                accept;
                            };
                            export where source = RTS_STATIC && net = ::/0 || source = RTS_BGP;
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
                            table bgp_v6;
                            igp table master6;
                            next hop self;
                            import none;
                            export where source = RTS_STATIC;
                        };
                    }
                ''}
                ${concatStringsSep "\n" (flip mapAttrsToList cfg.peers (name: value: ''
                    protocol bgp e${name} {
                        graceful restart on;
                        local as ASN;
                        neighbor ${value.address} as ${value.asn};
                        ipv4 {
                            import none;
                            export none;
                        };
                        ipv6 {
                            table bgp_v6;
                            igp table master6;
                            next hop self;
                            import filter {
                                utils_internet_reject_small_prefixes_v6();
                                utils_reject_long_aspaths();
                                utils_internet_reject_bogon();
                                utils_internet_reject_transit_paths();
                                utils_internet_roa();
                                accept;
                            };
                            export where source = RTS_STATIC;
                            import limit 1000 action block;
                        };
                    }
                ''))}
                ${optionalString cfg.upstream.enable ''
                    protocol static {
                        route ::/0 reject {
                            bgp_path.prepend(${cfg.upstream.asn});
                            bgp_next_hop = ${config.meta.v6};
                        };
                        ipv6 {
                            table bgp_v6;
                        };
                    }
                ''}
                ${cfg.extraBirdConfig}
            '';
        };
    };
}