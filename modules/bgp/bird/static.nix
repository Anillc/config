''
    protocol static {
        route 10.127.20.0/24 reject;
        ipv4 {
            table dn42_table_v4;
        };
    }

    protocol static {
        route 172.22.167.96/27 reject;
        ipv4 {
            table dn42_table_v4;
        };
    }

    protocol static {
        route fd10:127:cc::/48 reject;
        ipv6 {
            table dn42_table_v6;
        };
    }

    protocol static {
        route fdc9:83c1:d0ce::/48 reject;
        ipv6 {
            table dn42_table_v6;
        };
    }

    protocol static {
        route 2a0e:b107:1170::/48 reject;
        ipv6 {
            table internet_table_v6;
        };
    }

    protocol static {
        route 2a0e:b107:df5::/48 reject;
        ipv6 {
            table internet_table_v6;
        };
    }

    protocol static {
        route 2602:feda:da0::/44 reject;
        ipv6 {
            table internet_table_v6;
        };
    }
''