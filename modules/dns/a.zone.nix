{ pkgs, dns, ... }:  let
    name = "a";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1";
            adminEmail = "noc@anillc.cn";
            serial = 2022072002;
        };
        NS = [ "ns1.a." ];
        subdomains = {
            "ns1".A    = [ "10.11.1.1" ];
            "ns1".AAAA = [ "fd11:1::1" ];
            
            "sh".A     = [ "10.11.0.1" ];
            "sh".AAAA  = [ "fd11::1"   ];
            "tw".A     = [ "10.11.0.2" ];
            "tw".AAAA  = [ "fd11::2"   ];
            "hk".A     = [ "10.11.0.3" ];
            "hk".AAAA  = [ "fd11::3"   ];
            "de".A     = [ "10.11.0.6" ];
            "de".AAAA  = [ "fd11::6"   ];
            "wh".A     = [ "10.11.0.7" ];
            "wh".AAAA  = [ "fd11::7"   ];
            "jx".A     = [ "10.11.0.8" ];
            "jx".AAAA  = [ "fd11::8"   ];
            "fmt".A    = [ "10.11.0.9" ];
            "fmt".AAAA = [ "fd11::9"   ];

            "panel".CNAME = [ "sh.a." ];
            "db".CNAME = [ "sh.a." ];
            "bot".CNAME = [ "sh.a." ];
            "k8s".CNAME = [ "sh.a." ];

            "ca".CNAME = [ "fmt.a." ];

            # "ha".CNAME = [ "jx.a." ];
        };
    };
in pkgs.writeText name (dns.lib.toString name zone)