rec {
    meta = {
        id = 5;
        name = "lux";
        wg-public-key = "5gF5o4Cn5/J8t8aEGdCK/x5wKTLC8qpywNbqOc4J530=";
        syncthingId = "PMTKO4J-OWTTMXH-JNIVUHV-R4PZQMQ-WMJPXGT-B27RWEY-FPZ2DAQ-AP3LLQF";
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
            upstream = {
                enable = true;
                multihop = true;
                asn = "53667";
                address = "2605:6400:ffff::2";
                password = "lWAuRsXE";
            };
        };
        services.calibre-web = {
            enable = true;
            listen.ip = "127.0.0.1";
            options = {
                enableBookUploading = true;
                enableBookConversion = true;
            };
        };
        firewall.publicTCPPorts = [ 80 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "c.ff.ci" = {
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:8083";
                    };
                };
            };
        };
    };
}