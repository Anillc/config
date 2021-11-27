cfg: ''
    ipv4 table internet_table_v4;
    ipv6 table internet_table_v6;

    protocol pipe {
        table internet_table_v4;
        peer table master4;
        import none;
        export filter {
            if source ~ [RTS_BGP, RTS_OSPF] then {
                krt_prefsrc = INTERNET_SRC_v4;
            }
            accept;
        };
    }

    protocol pipe {
        table internet_table_v6;
        peer table master6;
        import none;
        export filter {
            if source ~ [RTS_BGP, RTS_OSPF] then {
                krt_prefsrc = INTERNET_SRC_v6;
            }
            accept;
        };
    }

    function internet_peers_filter_v4() {
        utils_internet_reject_small_prefixes_v4();
        utils_reject_long_aspaths();
        utils_internet_reject_bogon();
        utils_internet_reject_transit_paths();
        utils_internet_roa();
    }

    function internet_peers_filter_v6() {
        utils_internet_reject_small_prefixes_v6();
        utils_reject_long_aspaths();
        utils_internet_reject_bogon();
        utils_internet_reject_transit_paths();
        utils_internet_roa();
    }

    function internet_transits_filter_v4() {
        utils_internet_reject_small_prefixes_v4();
        utils_reject_long_aspaths();
        utils_internet_reject_bogon();
        utils_internet_roa();
    }

    function internet_transits_filter_v6() {
        utils_internet_reject_small_prefixes_v6();
        utils_reject_long_aspaths();
        utils_internet_reject_bogon();
        utils_internet_roa();
    }

    template bgp internet_peers {
        graceful restart;
        local as INTERNET_ASN;
        ipv4 {
            table internet_table_v4;
            igp table master4;
            next hop self;
            import filter {
                internet_peers_filter_v4();
                accept;
            };
            export where source = RTS_STATIC;
            import limit 1000 action block;
        };
        ipv6{
            table internet_table_v6;
            igp table master6;
            next hop self;
            import filter {
                internet_peers_filter_v6();
                accept;
            };
            export where source = RTS_STATIC;
            import limit 1000 action block;
        };
    }

    template bgp internet_transits {
        multihop;
        graceful restart on;
        local as INTERNET_ASN;
        ipv4 {
            table internet_table_v4;
            igp table master4;
            next hop self;
            import filter {
                internet_transits_filter_v4();
                accept;
            };
            export where source = RTS_STATIC;
        };
        ipv6{
            table internet_table_v6;
            igp table master6;
            next hop self;
            import filter {
                internet_transits_filter_v6();
                accept;
            };
            export where source = RTS_STATIC;
        };
    }

    ${if !cfg.bgpTransit.enable then "" else ''
        protocol bgp TRANSIT from internet_transits {
            neighbor ${cfg.bgpTransit.address} as ${cfg.bgpTransit.asn};
            multihop;
            graceful restart on;
            local as INTERNET_ASN;
            ${if cfg.bgpTransit.password == null then "" else ''
                password "${cfg.bgpTransit.password}";
            ''}
        }
    ''}

    ${builtins.foldl' (acc: x: ''
        ${acc}
        protocol bgp e${x.name} from internet_peers {
            neighbor ${x.linkLocal}%e${x.name} as ${x.asn};
        }
    '') "" cfg.bgpSettings.internet.peers}
''