{ pkgs, ... }: {
    systemd.network.networks.dbs-network = {
        matchConfig.Name = "dns";
        routes = [
            { routeConfig = { Destination = "172.22.167.126/32"; Table = 114; Protocol = 114; }; }
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
            networking.defaultGateway = {
                address = "172.22.167.97";
                interface = "dns";
            };
        };
    };
}