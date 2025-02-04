{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)   id name wg-public-key; peer = 16802; cost = 630;  }
        { inherit (hk.meta)     id name wg-public-key; peer = 11002; cost = 1000; }
        { inherit (koishi.meta) id name wg-public-key; peer = 11002; cost = 690;  }
        { inherit (lux.meta)    id name wg-public-key; peer = 11002; cost = 4000; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        DHCP = "yes";
    };
}