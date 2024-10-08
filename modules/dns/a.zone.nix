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
            "lux".A          = [ "10.11.0.5" ];
            "lux".AAAA       = [ "fd11::5"   ];
            "nnhr".A         = [ "10.11.0.6" ];
            "nnhr".AAAA      = [ "fd11::6"   ];
            "r".A            = [ "10.11.0.8" ];
            "r".AAAA         = [ "fd11::8"   ];

            "rsrc".A         = [ "10.11.1.5" ];

            "influxdb".CNAME = [ "cola.a." ];
            "panel".CNAME    = [ "cola.a." ];
            "db".CNAME       = [ "cola.a." ];
            "bot".CNAME      = [ "cola.a." ];
            "restic".CNAME   = [ "cola.a." ];

            "ca".CNAME       = [ "hk.a." ];

            "ha".CNAME       = [ "r.a." ];
            "qb".CNAME       = [ "r.a." ];
            "bot2".CNAME     = [ "r.a." ];

            "calibre".CNAME  = [ "lux.a." ];

        };
    };
in writeText name (dns.lib.toString name zone)