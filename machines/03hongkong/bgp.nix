{ ... }: let
    peers = [
        {
            name = "1888";
            endpoint = "hk1.dn42.ni.sb:22526";
            listen = 21888;
            v4 = "172.22.68.0";
            publicKey = "RyP2/n///CanKOD1EFtiPawHfUZb14+Fg0v4pbpsrnY=";
            asn = "4242421888";
            linkLocal = "fe80::1888";
        }
        {
            name = "testnet";
            listen = 23308;
            v4 = "172.23.99.70";
            publicKey = "FD4fpcBBIgKWGJ5KfEm2cnREL3sd+ZuVottzzZL1Czs=";
            asn = "4242423308";
            linkLocal = "fe80::3308:70";
        }
        {
            name = "ykis";
            endpoint = "hkg-node.ykis.moe:42526";
            listen = 22021;
            v4 = "172.20.51.129";
            publicKey = "69/4ORcfwc675TGVlaLcN08eCAuQmoYPSE4QXq3ozQg=";
            asn = "4242422021";
            linkLocal = "fe80::2021";
        }
        {
            name = "yurui";
            endpoint = "tp01.tw.node.argonauts.xyz:52526";
            listen = 22330;
            v4 = "172.23.32.5";
            publicKey = "LNpOdAZMc2RszmMB/JrvGoqLt8aE+p9JyYODKphzyyw=";
            asn = "4242422330";
            linkLocal = "fe80::2330:5";
            refresh = 60 * 60;
        }
        {
            name = "real186";
            endpoint = "cn-hongkong-01.edge.186526.xyz:22526";
            listen = 23764;
            publicKey = "hqYjyfevUoKhyVrRkKL04bcREE4MKEHo/qVtW3iGGAQ=";
            asn = "4242423764";
            linkLocal = "fe80::3764";
            extendedNextHop = true;
            refresh = 60 * 60;
        }
    ];
in {
    bgp = {
        enable = true;
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.100";
                v6 = "fdc9:83c1:d0ce::4";
                inherit peers;
            };
        };
        bgpTransit = {
            enable = true;
            asn = "38008";
            address = "2406:4440::1";
        };
        extraBirdConfig = ''
            protocol bgp dDAVIDLIU from dn42_peers {
                neighbor fe80::250:56ff:fea7:a99e%ens192 as 4242421876;
            }
            protocol static {
                ipv6;
                route 2406:4440::/64 via "ens192";
            }
            protocol bgp eAPERIX from internet_peers {
              neighbor 2406:4440::100 as 38008;
            }
        '';
    };
}
