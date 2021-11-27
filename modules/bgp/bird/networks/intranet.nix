pkgs: cfg: let
    costs = builtins.foldl' (acc: x: let
        ifname = "i${x.meta.name}";
    in ''
        ${acc}
        interface "${ifname}" {
            cost ptp_${ifname};
        };
    '') "" cfg.connect;
in ''
    ipv4 table ibgp_table_v4;
    ipv6 table ibgp_table_v6;
    ipv4 table igp_table_v4;
    ipv6 table igp_table_v6;

    protocol direct {
        ipv4 {
            table igp_table_v4;
        };
        ipv6 {
            table igp_table_v6;
        };
        interface "dummy2526";
    }

    protocol pipe {
        table ibgp_table_v4;
        peer table dn42_table_v4;
        import all;
        export filter {
            if !utils_dn42_valid() then reject;
            accept;
        };
    }

    protocol pipe {
        table ibgp_table_v6;
        peer table dn42_table_v6;
        import all;
        export filter {
            if !utils_dn42_valid() then reject;
            accept;
        };
    }

    protocol pipe {
        table ibgp_table_v4;
        peer table internet_table_v4;
        import all;
        export filter {
            if utils_dn42_valid() then reject;
            accept;
        };
    }

    protocol pipe {
        table ibgp_table_v6;
        peer table internet_table_v6;
        import all;
        export filter {
            if utils_dn42_valid() then reject;
            accept;
        };
    }

    protocol pipe {
        table igp_table_v4;
        peer table master4;
        import none;
        export filter {
            if net ~ [169.254.0.0/16+] then accept;
            if net ~ [172.16.0.0/12+, 10.0.0.0/8+] then {
                krt_prefsrc = DN42_SRC_v4;
            } else {
                krt_prefsrc = INTERNET_SRC_v4;
            }
            accept;
        };
    }

    protocol pipe {
        table igp_table_v6;
        peer table master6;
        import none;
        export filter {
            if net ~ [fd00::/8+] then {
                krt_prefsrc = DN42_SRC_v6;
            } else {
                krt_prefsrc = INTERNET_SRC_v6;
            }
            accept;
        };
    }

    protocol ospf v3 {
        ipv4 {
            table igp_table_v4;
            import all;
            export where source ~ [RTS_DEVICE, RTS_STATIC];
        };
        area 0 {
            ${costs}
        };
    }

    protocol ospf v3 {
        ipv6 {
            table igp_table_v6;
            import all;
            export where source ~ [RTS_DEVICE, RTS_STATIC];
        };
        area 0 {
            ${costs}
        };
    }

    template bgp ibgp_peers {
        graceful restart;
        local as INTRANET_ASN;
        ipv4 {
            table ibgp_table_v4;
            igp table master4;
            next hop self ebgp;
            import all;
            export all;
        };
        ipv6 {
            table ibgp_table_v6;
            igp table master6;
            next hop self ebgp;
            import all;
            export all;
        };
    }

    ${builtins.foldl' (acc: x: ''
        ${acc}
        ${if x.meta.name == cfg.meta.name then "" else ''
            protocol bgp i${x.meta.name} from ibgp_peers {
                neighbor 2602:feda:da0::${x.meta.id} as INTRANET_ASN;
            }
        ''}
    '') "" (import ../../../../machines).list}
''