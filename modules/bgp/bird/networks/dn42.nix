pkgs: cfg: ''
    ipv4 table dn42_table_v4;
    ipv6 table dn42_table_v6;

    protocol pipe {
        table dn42_table_v4;
        peer table master4;
        import none;
        export filter {
            if source ~ [RTS_BGP, RTS_OSPF] then {
                krt_prefsrc = DN42_SRC_v4;
            }
            accept;
        };
    }

    protocol pipe {
        table dn42_table_v6;
        peer table master6;
        import none;
        export filter {
            if source ~ [RTS_BGP, RTS_OSPF] then {
                krt_prefsrc = DN42_SRC_v6;
            }
            accept;
        };
    }

    function dn42_peers_filter() {
        utils_reject_long_aspaths();
        utils_dn42_reject_bogon();
        utils_dn42_roa();
        # Xiao Jin
        if net ~ [10.0.0.0/16+,192.168.2.0/24+] then reject;
    }

    template bgp dn42_peers {
        graceful restart;
        local as DN42_ASN;
        ipv4 {
            table dn42_table_v4;
            igp table master4;
            next hop self;
            import filter {
                dn42_peers_filter();
                accept;
            };
            export all;
            import limit 1000 action block;
        };
        ipv6{
            table dn42_table_v6;
            igp table master6;
            next hop self;
            import filter {
                dn42_peers_filter();
                accept;
            };
            export all;
            import limit 1000 action block;
        };
    }

    ${builtins.foldl' (acc: x: ''
        ${acc}
        protocol bgp d${x.name} from dn42_peers {
            neighbor ${x.linkLocal}%d${x.name} as ${x.asn};
            ${pkgs.lib.optionalString x.extendedNextHop ''
                ipv4 {
                    table dn42_table_v4;
                    igp table master4;
                    next hop self;
                    extended next hop;
                    import filter {
                        dn42_peers_filter();
                        accept;
                    };
                    export all;
                    import limit 1000 action block;
                };
            ''}
        }
    '') "" cfg.bgpSettings.dn42.peers}
''