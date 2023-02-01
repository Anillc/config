{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta)    name wg-public-key; listen = 11001; peer = 16803; cost = 100;  }
        { inherit (tw.meta)      name wg-public-key; listen = 11002;               cost = 1900; }
        { inherit (koishi.meta)  name wg-public-key; listen = 11004; peer = 11003; cost = 21;   }
        { inherit (lux.meta)     name wg-public-key; listen = 11005; peer = 11003; cost = 1870; }
        { inherit (jx.meta)      name wg-public-key; listen = 11008;               cost = 400;  }
        { inherit (fmt.meta)     name wg-public-key; listen = 11009; peer = 11003; cost = 1500; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        address = [ "103.152.35.32/24" "2406:4440::32/64" ];
        gateway = [ "103.152.35.254" "2406:4440::1" ];
    };
}