{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11001; }
        { inherit (sh2.meta) name wg-public-key; listen = 11005; }
        { inherit (wh.meta)  name wg-public-key; listen = 11007; peer = 11001; }
        { inherit (jx.meta)  name wg-public-key; listen = 11008; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
    wg.phone = {
        listen = 11451;
        publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
    };
    systemd.network.networks.phone = {
        matchConfig.Name = "phone";
        routes = [
            { routeConfig = { Destination = "10.11.1.1/32";  Table = 114; Protocol = 114; }; }
            { routeConfig = { Destination = "fd11:1::1/128"; Table = 114; Protocol = 114; }; }
        ];
    };
}