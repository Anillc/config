rec {
    meta = {
        id = 2;
        name = "tw";
        wg-public-key = "tQRTS5f+rRulwjf9zTlJ7Gtf9sONb+DKq4s6nsPvQXA=";
        syncthingId = "LBFAGHZ-E5MMLTP-5JJRV7H-3VRVDG2-NBP45WQ-WKDYK3L-HB2WDGK-VBCG7AC";
    };
    configuration = { config, pkgs, lib, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        bgp = {
            enable = true;
            peers.kskbix = {
                asn = "199594";
                address = "fe80::1980:1:1%eth1";
            };
        };
        dns.enable = false;
        networking.nameservers = lib.mkForce [ "127.0.0.1" ];
        services.dnsmasq = {
            enable = true;
            resolveLocalQueries = false;
            servers = [
                "/a/10.11.1.2"

                "/mycard.moe/10.11.1.2"
                "/momobako.com/10.11.1.2"
                "/yuzurisa.com/10.11.1.2"
                "/moecube.com/10.11.1.2"
                "/ygobbs.com/10.11.1.2"
                "/newwise.com/10.11.1.2"
                "/my-card.in/10.11.1.2"

                "114.114.114.114"
                "223.5.5.5"
                "8.8.8.8"
                "8.8.4.4"
            ];
        };
    };
}