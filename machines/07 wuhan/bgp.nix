meta: { config, ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        #connect = [ machines.shanghai machines.shanghai2 machines.beijing ];
        connect = [ machines.shanghai ];
        bgpSettings = {
            dn42.v4 = "172.22.167.103";
            dn42.v6 = "fdc9:83c1:d0ce::7";
        };
        extraBirdConfig = ''
            protocol static {
                ipv6;
                route 2406:840:1f:10::/64 via "ens19";
            }
            protocol bgp eZXIX from internet_peers {
                multihop;
                neighbor 2406:840:1f:10::1 as 140961;
            }
            protocol bgp eZXIX2 from internet_peers {
                multihop;
                neighbor 2406:840:1f:10::2 as 140961;
            }
            protocol bgp dDAVIDLIU from dn42_peers {
                neighbor fe80::3818:abff:fe08:f5d%ens18 as 4242421876;
            }
        '';
        inherit meta;
    };
} 