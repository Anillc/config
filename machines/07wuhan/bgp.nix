meta: { config, ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        #connect = [ machines.shanghai machines.shanghai2 machines.beijing ];
        connect = [ machines.shanghai ];
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.103";
                v6 = "fdc9:83c1:d0ce::7";
                peers = [
                    {
                        name = "real186";
                        endpoint = "cn-wuhan-01.edge.186526.xyz:11014";
                        publicKey = "WH89Ci8LqAgmFTAP+EquxSauDCPsxguwR7JmrUjlGTM=";
                        asn = "4242423764";
                        linkLocal = "fe80::3764";
                        extendedNextHop = true;
                        refresh = 60 * 60;
                    }
                    {
                        name = "dgy";
                        endpoint = "v4.bj.dn42.dgy.xyz:22526";
                        publicKey = "68jYn1Z0cBaIxFswSWFbkRvQIioEhMcThvJQ86LxkX8=";
                        asn = "4242420826";
                        linkLocal = "fe80::a0e:fb02";
                        extendedNextHop = true;
                    }
                    {
                        name = "hjm";
                        endpoint = "cn-zhongshan-01.dn42.yunyingstudio.cn:22526";
                        publicKey = "b0SqBBmXh/A7Ksag5ZT/rtqGL3HchRXcPuHwdTfBrC0=";
                        asn = "4242423663";
                        v4 = "172.23.114.2";
                        linkLocal = "fe80::1145";
                        refresh = 60 * 60;
                    }
                ];
            };
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
