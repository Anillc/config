{ ... }: {
    bgp = {
        enable = true;
        extraBirdConfig = ''
            protocol static {
                ipv6;
                route 2001:19f0:ffff::1/128 via fe80::fc00:3ff:fed1:df7a%enp1s0;
            }
            protocol bgp TRANSIT from internet_transits {
                neighbor 2001:19f0:ffff::1 as 64515;
                multihop;
                graceful restart on;
                local as INTERNET_ASN;
                password VULTR_PASSWORD;
                ipv6{
                    table internet_table_v6;
                    igp table master6;
                    next hop self;
                    import filter {
                        bgp_path.delete(UTILS_INTERNET_BOGON_ASNS);
                        if bgp_path.first != 20473 then bgp_path.prepend(20473);
                        # internet_transits_filter_v6();
                        accept;
                    };
                    export where source = RTS_STATIC;
                };
            }
        '';
    };
} 