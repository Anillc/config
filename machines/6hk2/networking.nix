{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta)    name wg-public-key; listen = 11001; peer = 16806; cost = 4000; }
        { inherit (tw.meta)      name wg-public-key; listen = 11002;               cost = 300;  }
        { inherit (hk.meta)      name wg-public-key; listen = 11002; peer = 11006; cost = 30;   }
        { inherit (koishi.meta)  name wg-public-key; listen = 11004; peer = 11006; cost = 40;   }
        { inherit (lux.meta)     name wg-public-key; listen = 11005; peer = 11006; cost = 1920; }
        { inherit (r.meta)       name wg-public-key; listen = 11008;               cost = 3640; }
        { inherit (fmt.meta)     name wg-public-key; listen = 11009; peer = 11006; cost = 1480; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens4";
        address = [ "10.7.99.29/16" ];
        gateway = [ "10.7.0.1" ];
    };
}