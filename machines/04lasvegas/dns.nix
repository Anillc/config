{ pkgs, ... }: {
    systemd.network.networks.dbs-network = {
        matchConfig.Name = "dns";
        addresses = [
            { addressConfig = { Address = "172.22.167.97/32"; }; }
            { addressConfig = { Address = "fdc9:83c1:d0ce::1/128"; }; }
        ];
        routes = [
            { routeConfig = { Destination = "172.22.167.126/32"; Table = 114; Protocol = 114; }; }
            { routeConfig = { Destination = "fdc9:83c1:d0ce::ff/128"; Table = 114; Protocol = 114; }; }
        ];
    };
    containers.dns = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.dns = {};
        config = { ... }: {
            imports = [
                ../../modules/dns
                ../../modules/networking/nftables.nix
            ];
            nixpkgs.overlays = [(self: super: {
                inherit (pkgs) dns;
            })];
            firewall.publicTCPPorts = [ 53 ];
            firewall.publicUDPPorts = [ 53 ];
            dns.enable = true;
            networking.interfaces.dns.ipv4.addresses = [{
                address = "172.22.167.126";
                prefixLength = 32;
            }];
            networking.interfaces.dns.ipv6.addresses = [{
                address = "fdc9:83c1:d0ce::ff";
                prefixLength = 128;
            }];
            networking.defaultGateway = {
                address = "172.22.167.97";
                interface = "dns";
            };
            networking.defaultGateway6 = {
                address = "fdc9:83c1:d0ce::1";
                interface = "dns";
            };
        };
    };
}