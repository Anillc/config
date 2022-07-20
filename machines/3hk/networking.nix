{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta)  name wg-public-key; listen = 11001; peer = 11003; cost = 400;  }
        { inherit (tw.meta)  name wg-public-key; listen = 11002;               cost = 1900; }
        { inherit (de.meta)  name wg-public-key; listen = 11006;               cost = 1900; }
        { inherit (wh.meta)  name wg-public-key; listen = 11007; peer = 21121; cost = 260;  }
        { inherit (jx.meta)  name wg-public-key; listen = 11008;               cost = 50;  }
        { inherit (fmt.meta) name wg-public-key; listen = 11009; peer = 11003; cost = 1500; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        address = [ "103.152.35.32/24" "2406:4440::32/64" ];
        gateway = [ "103.152.35.254" "2406:4440::1" ];
    };
}