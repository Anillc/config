meta: { ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        connect = [ machines.beijing machines.hongkong machines.shanghai2 machines.wuhan machines.school ];
        bgpSettings = {
            dn42 = {
                v4 = "172.22.167.105";
                v6 = "fdc9:83c1:d0ce::9";
                peers = [{
                    name = "yang";
                    listen = 21332;
                    v4 = "172.20.168.131";
                    publicKey = "H9ujJhN4QN4td0XKXvrP/wZEA/mFsHtr0VM9u1qIyz4=";
                    asn = "4242421332";
                    linkLocal = "fe80::1332";
                }
                {
                    name = "hertz";
                    listen = 21353;
                    v4 = "172.20.29.73";
                    endpoint = "121.41.36.113:22526";
                    publicKey = "UiMjULCBaKZjVjGIeKECf+TkGN4NLnhPCYHFDZds/Ss=";
                    asn = "4242421353";
                    linkLocal = "fe80::1353";
                }];
            };
        };
        inherit meta;
    };
} 