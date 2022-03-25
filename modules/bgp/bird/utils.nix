''
    ##### roa

    ### internet
    roa4 table utils_internet_roa4;
    roa6 table utils_internet_roa6;

    protocol rpki {
        roa4 {
            table utils_internet_roa4;
        };
        roa6 {
            table utils_internet_roa6;
        };
        remote "rtr.rpki.cloudflare.com" port 8282;
    }

    function utils_internet_roa() {
        if (roa_check(utils_internet_roa4, net, bgp_path.last) = ROA_INVALID ||
            roa_check(utils_internet_roa6, net, bgp_path.last) = ROA_INVALID) then {
            print "[internet] ROA check failed for ", net, " ASN ", bgp_path.last;
            reject;
        }
    }

    ### dn42
    roa4 table utils_dn42_roa4;
    roa6 table utils_dn42_roa6;

    protocol static {
        roa4 {
            table utils_dn42_roa4;
        };
        include "/var/bird/roa_dn42.conf";
    };

    protocol static {
        roa6 {
            table utils_dn42_roa6;
        };
        include "/var/bird/roa_dn42_v6.conf";
    };

    function utils_dn42_roa() {
        if (roa_check(utils_dn42_roa4, net, bgp_path.last) = ROA_INVALID ||
            roa_check(utils_dn42_roa6, net, bgp_path.last) = ROA_INVALID) then {
            print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
            reject;
        }
    }


    ##### bogon

    ### internet
    define UTILS_INTERNET_BOGON_ASNS = [
        0,                      # RFC 7607
        23456,                  # RFC 4893 AS_TRANS
        64496..64511,           # RFC 5398 and documentation/example ASNs
        64512..65534,           # RFC 6996 Private ASNs
        65535,                  # RFC 7300 Last 16 bit ASN
        65536..65551,           # RFC 5398 and documentation/example ASNs
        65552..131071,          # RFC IANA reserved ASNs
        4200000000..4294967294, # RFC 6996 Private ASNs
        4294967295              # RFC 7300 Last 32 bit ASN
    ];

    define UTILS_INTERNET_BOGON_PREFIXES_v4 = [
        0.0.0.0/8+,       # RFC 1122 'this' network
        10.0.0.0/8+,      # RFC 1918 private space
        100.64.0.0/10+,   # RFC 6598 Carrier grade nat space
        127.0.0.0/8+,     # RFC 1122 localhost
        169.254.0.0/16+,  # RFC 3927 link local
        172.16.0.0/12+,   # RFC 1918 private space
        192.0.2.0/24+,    # RFC 5737 TEST-NET-1
        192.88.99.0/24+,  # RFC 7526 6to4 anycast relay
        192.168.0.0/16+,  # RFC 1918 private space
        198.18.0.0/15+,   # RFC 2544 benchmarking
        198.51.100.0/24+, # RFC 5737 TEST-NET-2
        203.0.113.0/24+,  # RFC 5737 TEST-NET-3
        224.0.0.0/4+,     # multicast
        240.0.0.0/4+      # reserved
    ];

    define UTILS_INTERNET_BOGON_PREFIXES_v6 = [
        ::/8+,          # RFC 4291 IPv4-compatible, loopback, et al
        0100::/64+,     # RFC 6666 Discard-Only
        2001:2::/48+,   # RFC 5180 BMWG
        2001:10::/28+,  # RFC 4843 ORCHID
        2001:db8::/32+, # RFC 3849 documentation
        2002::/16+,     # RFC 7526 6to4 anycast relay
        3ffe::/16+,     # RFC 3701 old 6bone
        fc00::/7+,      # RFC 4193 unique local unicast
        fe80::/10+,     # RFC 4291 link local unicast
        fec0::/10+,     # RFC 3879 old site local unicast
        ff00::/8+       # RFC 4291 multicast
    ];

    function utils_internet_valid()
    int set bogon_asns;
    prefix set bogon_prefixes_v4;
    prefix set bogon_prefixes_v6; {
        bogon_asns = UTILS_INTERNET_BOGON_ASNS;
        if (bgp_path ~ bogon_asns) then return false;
        bogon_prefixes_v4 = UTILS_INTERNET_BOGON_PREFIXES_v4;
        if (net ~ bogon_prefixes_v4) then return false;
        bogon_prefixes_v6 = UTILS_INTERNET_BOGON_PREFIXES_v6;
        if (net ~ bogon_prefixes_v6) then return false;
        return true;
    }

    function utils_internet_reject_bogon() {
        if !utils_internet_valid() then {
            print "[internet] Reject: Bogon: ", net, " ", bgp_path;
            reject;
        }
    }

    ### dn42
    define UTILS_DN42_PREFIXES_v4 = [
        172.20.0.0/14{21,29}, # dn42
        172.20.0.0/24{28,32}, # dn42 Anycast
        172.21.0.0/24{28,32}, # dn42 Anycast
        172.22.0.0/24{28,32}, # dn42 Anycast
        172.23.0.0/24{28,32}, # dn42 Anycast
        172.31.0.0/16+,       # ChaosVPN
        10.100.0.0/14+,       # ChaosVPN
        10.127.0.0/16{16,32}, # neonetwork
        10.0.0.0/8{15,24}     # Freifunk.net
    ];

    define UTILS_DN42_PREFIXES_v6 = [
        fd00::/8{44,64} # ULA address space as per RFC 4193
    ];

    function utils_dn42_valid()
    prefix set prefixes_v4;
    prefix set prefixes_v6; {
        prefixes_v4 = UTILS_DN42_PREFIXES_v4;
        if (net ~ prefixes_v4) then return true;
        prefixes_v6 = UTILS_DN42_PREFIXES_v6;
        if (net ~ prefixes_v6) then return true;
        return false;
    }

    function utils_dn42_reject_bogon() {
        if !utils_dn42_valid() then {
            print "[dn42] Reject: Bogon prefix: ", net, " ", bgp_path;
            reject;
        }
    }


    ##### small prefixes

    ### internet
    function utils_internet_reject_small_prefixes_v4() {
        if (net.len > 24) then {
            print "[internet] Reject: Too small prefix: ", net, " ", bgp_path;
            reject;
        }
    }

    function utils_internet_reject_small_prefixes_v6() {
        if (net.len > 48) then {
            print "[internet] Reject: Too small prefix: ", net, " ", bgp_path;
            reject;
        }
    }



    ##### long aspaths

    function utils_reject_long_aspaths() {
        if ( bgp_path.len > 100 ) then {
            print "Reject: Too long AS path: ", net, " ", bgp_path;
            reject;
        }
    }


    ##### known transit

    ### internet
    define UTILS_TRANSIT_ASNS = [
        174,  # Cogent
        209,  # Qwest (HE carries this on IXPs IPv6 (Jul 12 2018))
        701,  # UUNET
        702,  # UUNET
        1239, # Sprint
        1299, # Telia
        2914, # NTT Communications
        3257, # GTT Backbone
        3320, # Deutsche Telekom AG (DTAG)
        3356, # Level3
        3491, # PCCW
        3549, # Level3
        3561, # Savvis / CenturyLink
        4134, # Chinanet
        5511, # Orange opentransit
        6453, # Tata Communications
        6461, # Zayo Bandwidth
        6762, # Seabone / Telecom Italia
        6830, # Liberty Global
        7018  # AT&T
    ];

    function utils_internet_reject_transit_paths()
        int set transit_asns; {
        transit_asns = UTILS_TRANSIT_ASNS;
        if (bgp_path ~ transit_asns) then {
            print "[internet] Reject: Transit ASNs found on IXP: ", net, " ", bgp_path;
            reject;
        }
    }

    ##### graceful restart

    ### internet
    function utils_graceful_shutdown() {
        if (65535, 0) ~ bgp_community then {
            bgp_local_pref = 0;
        }
    }
''