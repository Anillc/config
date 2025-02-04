{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)    id name wg-public-key; listen = 11001; peer = 16804; cost = 587;  }
        { inherit (product.meta) id name wg-public-key; listen = 11002;               cost = 690;  }
        { inherit (hk.meta)      id name wg-public-key; listen = 11003; peer = 11004; cost = 21;   }
        { inherit (lux.meta)     id name wg-public-key; listen = 11005; peer = 11004; cost = 1910; }
        { inherit (nnhr.meta)    id name wg-public-key; listen = 11006;               cost = 100;  }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
}