{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)    id name wg-public-key; listen = 11001; peer = 16805; cost = 2320; }
        { inherit (product.meta) id name wg-public-key; listen = 11002;               cost = 4000; }
        { inherit (hk.meta)      id name wg-public-key; listen = 11003; peer = 11005; cost = 1870; }
        { inherit (koishi.meta)  id name wg-public-key; listen = 11004; peer = 11005; cost = 1910; }
        { inherit (nnhr.meta)    id name wg-public-key; listen = 11006;               cost = 2550; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens3";
        address = [ "107.189.7.34/24" "2605:6400:30:e945::/48" ];
        gateway = [ "107.189.7.1" "2605:6400:30::1" ];
    };
}