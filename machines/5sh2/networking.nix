{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta) name wg-public-key; peer = 11005; cost = 80; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    firewall.enableSourceFilter = false;
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "192.168.1.110/24" ];
        gateway = [ "192.168.1.1" ];
        routes = [
            { routeConfig = { Destination = "10.0.0.0/16";     PreferredSource = config.meta.v4; Gateway = "192.168.1.1"; Table = 114; Protocol = 114; }; }
            { routeConfig = { Destination = "192.168.2.0/24";  PreferredSource = config.meta.v4; Gateway = "192.168.1.1"; Table = 114; Protocol = 114; }; }
            { routeConfig = { Destination = "192.168.22.0/24"; PreferredSource = config.meta.v4; Gateway = "192.168.1.1"; Table = 114; Protocol = 114; }; }
            # { routeConfig = { Destination = "5050:2333::/96";  PreferredSource = config.meta.v4; Gateway = "192.168.1.1"; Table = 114; Protocol = 114; }; }
        ];
    };
}