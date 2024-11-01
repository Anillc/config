{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ../../../machines lib;
in {
    config = {
        cfg.firewall.extraInputRules = "ip6 daddr ff02::5/128 accept";
        services.bird2 = {
            enable = true;
            config = lib.mkBefore ''
                router id ${config.cfg.meta.v4};

                ipv4 table igp_v4;
                ipv6 table igp_v6;

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
                        export all;
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
                protocol ospf v3 {
                    ipv4 {
                        table igp_v4;
                        import filter {
                            krt_prefsrc = ${config.cfg.meta.v4};
                            accept;
                        };
                        export where source = RTS_STATIC;
                    };
                    area 0 {
                        ${concatStringsSep "\n" (flip map (config.cfg.wgi) (x: ''
                            interface "i${x.name}" {
                                cost ${toString x.cost};
                            };
                        ''))}
                    };
                }
                protocol ospf v3 {
                    ipv6 {
                        table igp_v6;
                        import filter {
                            krt_prefsrc = ${config.cfg.meta.v6};
                            accept;
                        };
                        export where source = RTS_STATIC;
                    };
                    area 0 {
                        ${concatStringsSep "\n" (flip map (config.cfg.wgi) (x: ''
                            interface "i${x.name}" {
                                cost ${toString x.cost};
                            };
                        ''))}
                    };
                }
            '';
        };
    };
}