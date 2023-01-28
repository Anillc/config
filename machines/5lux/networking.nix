{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta)   name wg-public-key; listen = 11001; peer = 16805; cost = 2320; }
        { inherit (hk.meta)     name wg-public-key; listen = 11003; peer = 11005; cost = 1870; }
        { inherit (koishi.meta) name wg-public-key; listen = 11004; peer = 11005; cost = 1910; }
        { inherit (fmt.meta)    name wg-public-key; listen = 11009; peer = 11005; cost = 1420; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens3";
        address = [ "107.189.7.34/24" "2605:6400:30:e945::/48" ];
        gateway = [ "107.189.7.1" "2605:6400:30::1" ];
    };
}