rec {
    meta = {
        id = 9;
        name = "fmt";
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
        syncthingId = "B7R7642-DY6LI4N-VAOIQ4P-6FDXO55-GOIGUQQ-MWQN4T5-CB4E36R-KQJROAM";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./ca
        ];
        rsrc.enable = true;
        sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets.ca-key = {};
        };
        bgp = {
            enable = true;
            upstream = {
                enable = true;
                asn = "7720";
                address = "2602:fc1d:0:2::1";
                multihop = true;
            };
        };
        firewall.publicTCPPorts = [ 80 443 ];
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {
                "ca.a" = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = "https://ca.a:8443";
                    };
                };
            };
        };
    };
}