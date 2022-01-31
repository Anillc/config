{ pkgs, dns, ... }: let
    poem = import ../poem.nix pkgs;
    name = "f.a.d.0.a.d.e.f.2.0.6.2.ip6.arpa";
    zone = with dns.lib.combinators; {
        SOA = {
            nameServer = "ns1.awsl.ee.";
            adminEmail = "noc@anillc.cn";
            serial = 2021112201;
        };
        NS = [
            "ns1.awsl.ee."
            "ns2.awsl.ee."
        ];
        subdomains = {

        } // poem 20 ''
            孔乙己便涨红了脸
            额上的青筋条条绽出争辩道
            窃书不能算偷窃书
            读书人的事能算偷么
            接连便是难懂的话什么
            君子固穷什么者乎之类
            引得众人都哄笑起来
            店内外充满了快活的空气
        '';
    };
in pkgs.writeText name (dns.lib.toString name zone)