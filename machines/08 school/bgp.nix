meta: { config, ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        connect = [ machines.shanghai machines.beijing ];
        bgpSettings = {
            dn42.v4 = "172.22.167.107";
            dn42.v6 = "fdc9:83c1:d0ce::11";
        };
        extraBirdConfig = ''
            protocol static {
                route 2602:feda:da1:1::/96 via "br0";
                route fd10:127:cc:1:1::/96 via "br0";
                ipv6 {
                    table igp_table_v6;
                };
            }
            protocol static {
                route 10.127.20.128/25 via "br0";
                ipv4 {
                    table igp_table_v4;
                };
            }
        '';
        inherit meta;
    };
} 