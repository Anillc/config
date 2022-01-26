{ pkgs, dns, ... }: let
    name = "e.c.0.d.1.c.3.8.9.c.d.f.ip6.arpa";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1.an.dn42.";
            adminEmail = "noc@anillc.cn";
            serial = 2021112201;
        };
        NS = [ "ns1.an.dn42." ];
        subdomains = {
            "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "las.an.dn42." ];
            "3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "jp.an.dn42."  ];
            "4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "hk.an.dn42."  ];
            "6.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "de.an.dn42."  ];
            "7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "wh.an.dn42."  ];
            "8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "hz.an.dn42."  ];
            "9.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0".PTR = [ "sh.an.dn42."  ];
        };
    };
in pkgs.writeText name (dns.lib.toString name zone)