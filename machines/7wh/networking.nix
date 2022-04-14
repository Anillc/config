{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta)  name wg-public-key;                 peer = 11007; cost = 200; }
        { inherit (hk.meta)  name wg-public-key; listen = 21121; peer = 11007; cost = 260; }
        { inherit (jx.meta)  name wg-public-key; listen = 21122;               cost = 160; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "10.56.1.12/24" "2404:f4c0:5156:1::12/64" ];
        gateway = [ "10.56.1.1" "2404:f4c0:5156:1::1" ];
    };
    systemd.network.networks.ix-network = {
        matchConfig.Name = "ens19";
        address = [ "2406:840:1f:10::14:2055:1/64" ];
    };
}