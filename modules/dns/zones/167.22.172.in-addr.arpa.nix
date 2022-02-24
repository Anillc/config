{ pkgs, dns, ... }: let
    name = "96/27.167.22.172.in-addr.arpa";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1.an.dn42.";
            adminEmail = "noc@anillc.cn";
            serial = 2021112201;
        };
        NS = [ "ns1.an.dn42." ];
        subdomains = {
            "97".PTR  = [ "las.an.dn42." ];
            "99".PTR  = [ "jp.an.dn42."  ];
            "100".PTR = [ "hk.an.dn42."  ];
            "102".PTR = [ "de.an.dn42."  ];
            "103".PTR = [ "wh.an.dn42."  ];
            "104".PTR = [ "hz.an.dn42."  ];
            "105".PTR = [ "sh.an.dn42."  ];
            "106".PTR = [ "sh2.an.dn42." ];
            "107".PTR = [ "jx.an.dn42."  ];
            "108".PTR = [ "fmt.an.dn42." ];
            "125".PTR = [ "dns.an.dn42." ];
            "126".PTR = [ "ns1.an.dn42." ];
        };
    };
in pkgs.writeText name (dns.lib.toString name zone)