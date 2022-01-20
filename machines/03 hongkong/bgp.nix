meta: { ... }: let
    machines = (import ./..).set;
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
            name = "burble";
            endpoint = "103.73.66.189:22526";
            listen = 22601;
            v4 = "172.23.32.5";
            publicKey = "0E6G2hADdSKbE4XUX3cUph0GHIiohr2dwN2jURdoeGY=";
            asn = "4242422601";
            linkLocal = "fe80::42:2601:23:1";
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
        connect = [ machines.shanghai machines.lasvegas machines.de ];
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.100";
                v6 = "fdc9:83c1:d0ce::4";
                inherit peers;
            };
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
            function is_chinese_routes() {
                return bgp_path ~ [
                    # 移动
                    9808, 141425, 24400, 24444, 24445, 24547, 38019, 56040, 56041, 56042, 56044, 56045, 56046, 56047, 56048, 132501, 132510, 132511, 132525,
                    # 联通
                    4659, 4799, 4837, 9929, 18344, 4808, 4814, 10206, 17620, 17621, 17622, 17623, 17816, 17788, 17789, 17790, 17791, 134543, 135061, 136958, 136959, 134532, 137539, 4859, 9308, 9812, 17430, 17773, 17968, 17969, 18243, 23771, 23851, 24137, 24139, 24143, 37937, 37963, 38057, 45062, 45113, 59077, 56282, 63554, 63540, 63707, 131519, 131577, 50915, 10099, 18488, 20940, 20940, 4775, 8449, 21299, 8529, 45629, 9873, 4609, 131279, 38378, 63659, 139007, 63705, 63581, 56006, 59068, 133118, 133119, 134542, 138421, 140707, 140726, 140886, 140979, 37943, 137788, 131506, 63722, 131562, 139908, 140720, 55990, 140716, 139136, 137799, 140717,
                    # 电信
                    4134, 7639, 9395, 9402, 7467, 9823, 9802, 9580, 9818, 9817, 9307, 4814, 9815, 9305, 8193, 12997, 17779, 17963, 17490, 17883, 17923, 17897, 17896, 17672, 17785, 9813, 12365, 25389, 17778, 28910, 17967, 23610, 4609, 7643, 29385, 23840, 18220, 23841, 4751, 23850, 18723, 34414, 7552, 41798, 8393, 5434, 29555, 8430, 29046, 29355, 23842, 24410, 10695, 10226, 23930, 24403, 24487, 24426, 24086, 9318, 37960, 18403, 38378, 38369, 38361, 45149, 45250, 5089, 25809, 12885, 24139, 17916, 9484, 24460, 45070, 45911, 45101, 45112, 45899, 40633, 9299, 4775, 45464, 7491, 45832, 17550, 45464, 21433, 15084, 23964, 38722, 24079, 9927, 45647, 9821, 23862, 45209, 45600, 17894, 23732, 24471, 45221, 4797, 45343, 45218, 38304, 55462, 45899, 45095, 55649, 31055, 45816, 45102, 9498, 38344, 23839, 4657, 26484, 32787, 3216, 18106, 133424, 3462, 134755, 9729, 55967, 133613, 63450, 24246, 63558, 137689, 137688, 32243, 137692, 137691, 15802, 3225, 30844, 140636, 140638, 58511, 136548, 9304, 55818, 38001, 36891, 64050, 9231, 58655, 136743, 131941, 45558, 32242, 58073, 3214, 40065, 20150, 41378, 7575, 22769, 138628, 140547, 398851, 24429, 398968, 395886, 7473, 58519, 142135, 132203
                ];
            }

            protocol bgp TRANSIT from internet_transits {
                neighbor 2406:4440::1 as 38008;
                ipv6 {
                    table internet_table_v6;
                    igp table master6;
                    next hop self;
                    import filter {
                    internet_transits_filter_v6();
                    if is_chinese_routes() then {
                        bgp_local_pref = 200;
                    }
                    accept;
                    };
                    export where source = RTS_STATIC;
                };
            }
        '';
        inherit meta;
    };
}
