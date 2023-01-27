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
        bgp.enable = true;
        firewall.publicTCPPorts = [ 4001 80 ];
        firewall.publicUDPPorts = [ 4001 ];
        # kubo in the future
        # services.kubo.enable = true;
        services.ipfs = {
            enable = true;
            extraConfig = {
                API.HTTPHeaders.Access-Control-Allow-Origin = [ "https://kubo.a" "https://webui.ipfs.io" ];
            };
        };
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "kubo.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyWebsockets = true;
                        proxyPass = "http://127.0.0.1:5001";
                    };
                };
            };
        };
    };
}