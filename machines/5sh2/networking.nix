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
        address = [ "192.168.1.110/24" "fe80::115/64" ];
        gateway = [ "192.168.1.1" ];
        routes = [
            { routeConfig = { Destination = "10.50.0.0/16";    PreferredSource = config.meta.v4; Gateway = "192.168.1.11"; Table = 114; Protocol = 114; }; }
            { routeConfig = { Destination = "fddd:5050::/64";  PreferredSource = config.meta.v6; Gateway = "fe80::c274:2bff:feff:a618"; Table = 114; Protocol = 114; }; }
        ];
    };
}