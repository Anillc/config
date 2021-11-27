{ pkgs, dns, ... }: let
    name = "an.neo";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1.an.dn42.";
            adminEmail = "noc@anillc.cn";
            serial = 2021112201;
        };
        NS = [ "ns1.an.dn42." ];
        A = [ "172.22.167.97" ];
        AAAA = [ "fdc9:83c1:d0ce::1" ];
        subdomains = {
        };
    };
in pkgs.writeText name (dns.lib.toString name zone)