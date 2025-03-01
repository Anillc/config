{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)    id name wg-public-key; listen = 11001; peer = 16803; cost = 560; }
        { inherit (product.meta) id name wg-public-key; listen = 11002;               cost = 764; }
        { inherit (r.meta)       id name wg-public-key; listen = 11008;               cost = 570; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        DHCP = "yes";
    };
}