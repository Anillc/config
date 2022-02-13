{ config, pkgs, ... }: let
    # TODO:yang 
    peers = [
        {
            name = "2188";
            endpoint = "137.184.31.38:22526";
            listen = 22188;
            v4 = "172.23.231.119";
            publicKey = "MPvJSiuwE2t9BUe/aRqu4MvHBJh/G20HKcH3d1aVDhQ=";
            asn = "4242422188";
            linkLocal = "fe80::2188";
        }
        {
            name = "ayumu";
            endpoint = "las.dneo.moeternet.com:22526";
            listen = 22464;
            v4 = "172.20.191.194";
            publicKey = "viR4CoaJTBHROo/Bgbb27hQ2ttr8AbByGY/yOz3D3GY=";
            asn = "4242422464";
            linkLocal = "fe80::2464";
        }
        {
            name = "azurite";
            endpoint = "nv1.us.lapinet27.com:22526";
            listen = 22032;
            v4 = "172.22.180.65";
            publicKey = "v3MmT35p23jdEEFbwpa5Us6JfS1yjec3XiFBcFrErzA=";
            asn = "4242422032";
            linkLocal = "fe80::2032";
        }
        {
            name = "ccp";
            endpoint = "dn42.ccp.ovh:22526";
            listen = 21123;
            v4 = "172.20.47.1";
            publicKey = "Z6OKJSR1sxMBgUd1uXEe/UxoBsOvRgbTnexy7z/ryUI=";
            asn = "4242421123";
            linkLocal = "fe80::1123";
        }
        {
            name = "dgy";
            endpoint = "204.44.93.85:22526";
            listen = 20826;
            v4 = "172.23.196.0";
            publicKey = "IXjFALJFTr24HAhXKDsCnTRXmlc3kJHJiR4Nr44l5Uw=";
            asn = "4242420826";
            linkLocal = "fe80::a0e:fb02";
        }
        {
            name = "davidliu";
            endpoint = "209.141.52.24:22526";
            listen = 21876;
            v4 = "172.22.66.48";
            publicKey = "WhAPxyV6Sokeo8eRSETJw/kwaYCPq4Rw7ztjevenJWc=";
            asn = "4242421876";
            linkLocal = "fe80::1876";
        }
        {
            name = "jerry";
            endpoint = "us.neo.jerryxiao.cc:50103";
            listen = 23618;
            v4 = "172.20.51.112";
            publicKey = "d4b17hQ0bT3ae1oooGoIYDgNc5NH+9o/ry+VsoEgrAk=";
            asn = "4242423618";
            linkLocal = "fe80::3618";
        }
        {
            name = "jlu5";
            endpoint = "dn42-us-las01.jlu5.com:52526";
            listen = 21080;
            v4 = "172.20.229.126";
            publicKey = "oHxFupY7yiSRmRpWB2mfXzfXam5fGyxQ313TWszk0Es=";
            asn = "4242421080";
            linkLocal = "fe80::1080:126";
        }
        {
            name = "kato";
            endpoint = "209.141.32.202:22526";
            listen = 23724;
            v4 = "172.23.215.228";
            publicKey = "W8IoIklrTsWKDJEJ35kh1aHPO9CIyyfNBF/MptzX4jw=";
            asn = "4242423724";
            linkLocal = "fe80::3724";
        }
        {
            name = "lantian";
            endpoint = "hostdare.lantian.pub:22526";
            listen = 22547;
            v4 = "172.22.76.185";
            publicKey = "zyATu8FW392WFFNAz7ZH6+4TUutEYEooPPirwcoIiXo=";
            asn = "4242422547";
            linkLocal = "fe80::2547";
        }
        {
            name = "lss233";
            endpoint = "lax.n.lss233.com:52526";
            listen = 21826;
            v4 = "172.20.143.50";
            publicKey = "okfX4nra3vEz8TdXD08142TAi9YCYXOJAbF0DAx/dnw=";
            asn = "4242421826";
            linkLocal = "fe80::1826";
        }
        {
            name = "miaotony";
            endpoint = "lv1.us.dn42.miaotony.xyz:22526";
            listen = 22688;
            v4 = "172.23.6.6";
            publicKey = "vfrrbtKAO5438daHrTD0SSS8V6yk78S/XW7DeFrYLXA=";
            asn = "4242422688";
            linkLocal = "fe80::2688";
        }
        {
            name = "moecast";
            endpoint = "fmt1.dn42.cas7.moe:22526";
            listen = 20604;
            v4 = "172.23.89.4";
            publicKey = "1dJpFLegKHKButkXqbv1KLLMTmS6KtFkWBz6GRo2uxE=";
            asn = "4242420604";
            linkLocal = "fe80::604:4";
        }
        {
            name = "nicho";
            endpoint = "lax2.sc00.org:22526";
            listen = 21288;
            v4 = "172.20.233.131";
            publicKey = "PGTK1pzAYtSGoaPYfpEBCwm3S3gYAra3WkSMtshFfW8=";
            asn = "4242421288";
            linkLocal = "fe80::1288";
        }
        {
            name = "sunnet";
            endpoint = "173.82.18.212:22526";
            listen = 23088;
            v4 = "172.21.100.193";
            publicKey = "QSAeFPotqFpF6fFe3CMrMjrpS5AL54AxWY2w1+Ot2Bo=";
            asn = "4242423088";
            linkLocal = "fe80::3088:193";
        }
        {
            name = "tnull";
            endpoint = "173.82.121.213:22526";
            listen = 22006;
            v4 = "172.23.3.233";
            publicKey = "Ce58ux2VVr+v6IMC3CZvB3URVao11Yu6+p14Dt7ncjY=";
            asn = "4242422006";
            linkLocal = "fe80::2006";
        }
        {
            name = "yuuta";
            endpoint = "sjc1.us.dn42.yuuta.moe:22526";
            listen = 22980;
            v4 = "172.23.105.3";
            publicKey = "HgLHUbU6RRme+Vib6pFgL82mgX0fkMp8zcsrZ+EdMBQ=";
            presharedKeyFile = config.sops.secrets.wg-yuuta-preshared-key.path;
            asn = "4242422980";
            linkLocal = "fe80::2980";
        }
        {
            name = "moe233";
            endpoint = "64.227.97.100:22526";
            listen = 20253;
            publicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
            asn = "4242420253";
            linkLocal = "fe80::253";
            extendedNextHop = true;
        }
        {
            name = "kskb";
            endpoint = "us.kskb.eu.org:22526";
            listen = 21817;
            publicKey = "dZzVdXbQPnWPpHk8QfW/p+MfGzAkMBuWpxEIXzQCggY=";
            asn = "4242421817";
            linkLocal = "fe80::1817";
            extendedNextHop = true;
        }
        {
            name = "mika";
            endpoint = "lax1-us.bugsur.xyz:22526";
            listen = 23743;
            publicKey = "x8nuSiQ4B9fyV/Qe7htgsjeuPMQPziAvOigOt+FWIgs=";
            asn = "4242423743";
            linkLocal = "fe80::2434";
            extendedNextHop = true;
        }
        {
            name = "real186";
            endpoint = "us-losangls-01.edge.186526.xyz:22526";
            listen = 23764;
            publicKey = "lqZ+0q3K+Ju2RQUOPNmAxleRUdtnsxvBu1TAtUqUAHM=";
            asn = "4242423764";
            linkLocal = "fe80::3764";
            extendedNextHop = true;
        }
    ];
in {
    bgp = {
        enable = true;
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.97";
                v6 = "fdc9:83c1:d0ce::1";
                inherit peers;
            };
        };
        bgpTransit = {
            enable = true;
            asn = "53667";
            address = "2605:6400:ffff::2";
            password = "BUYVM_PASSWORD";
        };
        extraBirdConfig = ''
            protocol static {
                route 2a0e:b107:1171::/48 reject;
                ipv6 {
                    table internet_table_v6;
                };
            }
            protocol static { 
                ipv6;
                route 2605:6400:ffff::2/128 via "ens3" {
                    krt_prefsrc = 2605:6400:20:677::;
                };
                route 2605:6400:20:25d0:a5b7:c93a:873d:d27c/128 via "ens3" {
                    krt_prefsrc = 2605:6400:20:677::;
                };
                route 2605:6400:ffff::/64 via fe80::4e96:1400:c8a8:5ff0%ens3;            # Buyvm Router
                route 2604:4d40:2000::/64 via fe80::4e96:1400:c8a8:5ff0%ens3;            # Buyvm Gateway
                route 2605:6400:20::/48 via fe80::4e96:1400:c8a8:5ff0%ens3;              # Buyvm Customers
                route 2001:470:1:964::1/128 via fe80::4e96:1400:c8a8:5ff0%ens3;          # He
                route 2001:550:2:c8::28:1/128 via fe80::4e96:1400:c8a8:5ff0%ens3;        # Cogent
                route 2001:668:0:3:ffff:2:0:1c6d/128 via fe80::4e96:1400:c8a8:5ff0%ens3; # GTT
                route fdeb:fc8d:4786:60b7::2/128 via fe80::4e96:1400:c8a8:5ff0%ens3;     # anyNode
            }
            protocol bgp eMOECAST from internet_transits {
                direct;
                neighbor fe80::604%emoecast as 141237;
            }
            protocol bgp dkioubit from dn42_peers {
                neighbor fe80::ade0%dkioubit as 4242423914;
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
            protocol bgp dtech9 from dn42_peers {
                neighbor fe80::1588%dtech9 as 4242421588;
                default bgp_local_pref 50;
            }
            protocol bgp enyaa from internet_peers {
                neighbor 2605:6400:20:25d0:a5b7:c93a:873d:d27c as 142553;
            }
        '';
    };
    wg.emoecast = {
        listen = 10002;
        ip = [{ addr = "fe80::2526/64"; }];
        publicKey = "1dJpFLegKHKButkXqbv1KLLMTmS6KtFkWBz6GRo2uxE=";
        endpoint = "fmt1.dn42.cas7.moe:32526";
    };
    wg.dkioubit = {
        ip = [{ addr = "fe80::ade1/64"; }];
        publicKey = "6Cylr9h1xFduAO+5nyXhFI1XJ0+Sw9jCpCDvcqErF1s=";
        endpoint = "us2.g-load.eu:22526";
    };
    wg.dtech9 = {
        listen = 21588;
        ip = [
            { addr = "fe80::100/64"; }
            { addr = "${config.bgp.bgpSettings.dn42.v4}/32"; peer = "172.20.16.140/32"; }
        ];
        publicKey = "iEZ71NPZge6wHKb6q4o2cvCopZ7PBDqn/b3FO56+Hkc=";
        endpoint = "us-dal01.dn42.tech9.io:51061";
    };
} 
