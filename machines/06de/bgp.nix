{ config, ... }: {
    bgp = {
        enable = true;
        bgpSettings = {
            dn42.peers = [
                {
                    name = "mika";
                    endpoint = "zrh1-ch.bugsur.xyz:22526";
                    publicKey = "MUShSTyApCSU7Rc1TLCGKiyyOBAIkLzEEVCpOf6wbQ0=";
                    asn = "4242423743";
                    linkLocal = "fe80::2434";
                    extendedNextHop = true;
                    refresh = 60 * 60;
                }
                {
                    name = "dgy";
                    endpoint = "v4.ru.dn42.dgy.xyz:22526";
                    publicKey = "Y8E2cd2DKr7hZ3qs1WgU+2l+qWHaOxw4vFPAGevpiW0=";
                    asn = "4242420826";
                    linkLocal = "fe80::826";
                    extendedNextHop = true;
                    refresh = 60 * 60;
                }
            ];
        };
        bgpTransit = {
            enable = true;
            asn = "135395";
            address = "2a0f:9400:7a00::1";
        };
        extraBirdConfig = ''
            protocol static {
                ipv6;
                route 2a0f:9400:7a00::/48 via 2a0f:9400:7a00::1;
            }
            protocol static {
                ipv6;
                route 2a0f:9400:7a00:3333::/64 via "ens192";
            }
            # collapse
            # protocol bgp eHZIX from internet_peers {
            #     neighbor 2a0f:9400:7a00:3333:1111::1 as 64555;
            # }
            protocol bgp dDAVIDLIU from dn42_peers {
                neighbor fe80::291:dff:fe12:5051%ens192 as 4242421876;
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
            }
            protocol bgp dKSKB from dn42_peers {
                neighbor fe80::2d1:d5ff:fe65:d8d4%ens160 as 4242421817;
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
            }
            protocol bgp dKAI from dn42_peers {
                neighbor fe80::2f0:80ff:fe11:f048%ens192 as 4242421488;
            }
        '';
    };
} 
