{ writeText, inputs, ... }:  let
    dns = inputs.dns;
    name = "a";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1";
            adminEmail = "void@anil.lc";
            serial = 2024102401;
        };
        NS = [ "ns1.a." ];
        subdomains = {
            "ns1".A          = [ "10.11.1.1" ];
            "ns1".AAAA       = [ "fd11:1::1" ];

            "cola".A         = [ "10.11.0.1" ];
            "cola".AAAA      = [ "fd11::1"   ];
            "product".A      = [ "10.11.0.2" ];
            "product".AAAA   = [ "fd11::2"   ];
            "sum".A          = [ "10.11.0.3" ];
            "sum".AAAA       = [ "fd11::3"   ];
            "lux".A          = [ "10.11.0.5" ];
            "lux".AAAA       = [ "fd11::5"   ];
            "r".A            = [ "10.11.0.8" ];
            "r".AAAA         = [ "fd11::8"   ];
        };
    };
in writeText name (dns.lib.toString name zone)