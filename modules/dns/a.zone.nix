{ writeText, inputs, ... }:  let
    dns = inputs.dns;
    name = "a";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1";
            adminEmail = "noc@anillc.cn";
            serial = 2022072002;
        };
        NS = [ "ns1.a." ];
        subdomains = {
            "ns1".A          = [ "10.11.1.1" ];
            "ns1".AAAA       = [ "fd11:1::1" ];
            
            "cola".A         = [ "10.11.0.1" ];
            "cola".AAAA      = [ "fd11::1"   ];
            "tw".A           = [ "10.11.0.2" ];
            "tw".AAAA        = [ "fd11::2"   ];
            "hk".A           = [ "10.11.0.3" ];
            "hk".AAAA        = [ "fd11::3"   ];
            "koishi".A       = [ "10.11.0.4" ];
            "koishi".AAAA    = [ "fd11::4"   ];
            "wh".A           = [ "10.11.0.7" ];
            "wh".AAAA        = [ "fd11::7"   ];
            "jx".A           = [ "10.11.0.8" ];
            "jx".AAAA        = [ "fd11::8"   ];
            "fmt".A          = [ "10.11.0.9" ];
            "fmt".AAAA       = [ "fd11::9"   ];

            "rsrc".A         = [ "10.11.1.5" ];

            "influxdb".CNAME = [ "cola.a." ];
            "panel".CNAME    = [ "cola.a." ];
            "db".CNAME       = [ "cola.a." ];

            "bot".CNAME      = [ "hk.a." ];

            "ca".CNAME       = [ "fmt.a." ];

            # "ha".CNAME      = [ "jx.a." ];
            "qb".CNAME       = [ "jx.a." ];
            
        };
    };
in writeText name (dns.lib.toString name zone)