{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta) name wg-public-key; listen = 11001; peer = 16804; cost = 587;  }
        { inherit (hk.meta)   name wg-public-key; listen = 11003; peer = 11004; cost = 21;   }
        { inherit (lux.meta)  name wg-public-key; listen = 11005; peer = 11004; cost = 1910; }
        { inherit (hk2.meta)  name wg-public-key; listen = 11006; peer = 11004; cost = 40;   }
        { inherit (fmt.meta)  name wg-public-key; listen = 11009; peer = 11004; cost = 1500; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
}