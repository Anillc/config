{ config, pkgs, ... }: {
    firewall.extraNatRules = ''
        meta iifname dnsmasq meta oifname "en*" masquerade
    '';
    net = {
        addresses = [
            { address = "${config.meta.v4}/32";  interface = "dnsmasq"; }
            { address = "${config.meta.v6}/128"; interface = "dnsmasq"; }
        ];
        routes = [
            { dst = "172.22.167.125/32";      interface = "dnsmasq"; proto = 114; table = 114; }
            { dst = "fdc9:83c1:d0ce::fe/128"; interface = "dnsmasq"; proto = 114; table = 114; }
        ];
    };
    # TODO
    systemd.services.net.partOf = [ "container@dnsmasq.service" ];
    systemd.services."container@dnsmasq".before = [ "net.service" ];
    containers.dnsmasq = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.dnsmasq = {};
        config = { ... }: {
            imports = [ ../networking/def ];
            nixpkgs.overlays = [(self: super: {
                inherit (pkgs) dns;
            })];
            firewall.publicTCPPorts = [ 53 ];
            firewall.publicUDPPorts = [ 53 ];
            networking.interfaces.dnsmasq.ipv4.addresses = [{ address = "172.22.167.125"; prefixLength = 32; }];
            networking.interfaces.dnsmasq.ipv6.addresses = [{ address = "fdc9:83c1:d0ce::fe"; prefixLength = 128; }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "dnsmasq"; };
            networking.defaultGateway6 = { address = config.meta.v6; interface = "dnsmasq"; };
            services.dnsmasq = {
                enable = true;
                resolveLocalQueries = false;
                servers = [
                    "/an.dn42/172.22.167.126"
                    "/an.neo/172.22.167.126"
                    "/dn42/172.20.0.53"
                    "/dn42/172.23.0.53"
                    "/neo/172.20.0.53"
                    "/neo/172.23.0.53"
                    "114.114.114.114"
                    "223.5.5.5"
                    "8.8.8.8"
                    "8.8.4.4"
                ];
            };
        };
    };
}