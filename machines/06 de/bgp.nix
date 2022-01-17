meta: { config, ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        connect = [ machines.lasvegas machines.hongkong ];
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.102";
                v6 = "fdc9:83c1:d0ce::6";
                peers = [{
                    name = "baoshuo";
                    endpoint = "eu1.dn42.as141776.net:42526";
                    v4 = "172.23.250.91";
                    publicKey = "edTGR6Fs0rwAmGzWx/Zl6xxksYveRo+d75wWjxQYN0g=";
                    asn = "4242420247";
                    linkLocal = "fe80::247";
                }];
            };
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
            protocol bgp dKAI from dn42_peers {
                neighbor fe80::2f0:80ff:fe11:f048%ens192 as 4242421488;
            }
        '';
        inherit meta;
    };
} 