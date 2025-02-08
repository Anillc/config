{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)   id name wg-public-key; peer = 16806; cost = 380;  }
        { inherit (hk.meta)     id name wg-public-key; peer = 11006; cost = 110;  }
        { inherit (lux.meta)    id name wg-public-key; peer = 11006; cost = 2550; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        DHCP = "ipv4";
    };
}