rec {
    meta = {
        id = 9;
        name = "fmt";
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./networking.nix
            ./ca
        ];
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
                # TODO: remove
                "feishu.anillc.cn" = {
                    locations."/" = {
                        proxyPass = "http://10.11.2.133:8005";
                    };
                };
            };
        };
    };
}