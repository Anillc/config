{ ... }: {
    networking.nameservers = [ "172.20.0.53" "223.5.5.5" ];
    services.bird-lg-go-frontend = {
        enable = true;
        domain = "an.dn42";
        servers = [ "las" "jp" "hk" "de" "wh" "sh" "sh2" "jx" ];
    };
    bgp = {
        enable = true;
        bgpSettings = {
            dn42.peers = [
                {
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
                }
            ];
        };
    };
} 