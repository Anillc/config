{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta)   name wg-public-key; peer = 16806; cost = 380;  }
        { inherit (hk.meta)     name wg-public-key; peer = 11006; cost = 110;  }
        { inherit (koishi.meta) name wg-public-key; peer = 11006; cost = 100;  }
        { inherit (lux.meta)    name wg-public-key; peer = 11006; cost = 2550; }
        { inherit (fmt.meta)    name wg-public-key; peer = 11006; cost = 1600; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        DHCP = "ipv4";
    };
}