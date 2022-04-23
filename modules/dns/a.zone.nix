{ pkgs, dns, ... }:  let
    name = "a";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1";
            adminEmail = "noc@anillc.cn";
            serial = 2022042301;
        };
        NS = [ "ns1.a." ];
        subdomains = {
            "ns1".A    = [ "10.11.1.1" ];
            "ns1".AAAA = [ "fd11:1::1" ];
            
            "sh".A     = [ "10.11.0.1" ];
            "sh".AAAA  = [ "fd11::1"   ];
            "hk".A     = [ "10.11.0.3" ];
            "hk".AAAA  = [ "fd11::3"   ];
            "las".A    = [ "10.11.0.4" ];
            "las".AAAA = [ "fd11::4"   ];
            "sh2".A    = [ "10.11.0.5" ];
            "sh2".AAAA = [ "fd11::5"   ];
            "de".A     = [ "10.11.0.6" ];
            "de".AAAA  = [ "fd11::6"   ];
            "wh".A     = [ "10.11.0.7" ];
            "wh".AAAA  = [ "fd11::7"   ];
            "jx".A     = [ "10.11.0.8" ];
            "jx".AAAA  = [ "fd11::8"   ];
            "fmt".A    = [ "10.11.0.9" ];
            "fmt".AAAA = [ "fd11::9"   ];
        };
    };
in pkgs.writeText name (dns.lib.toString name zone)