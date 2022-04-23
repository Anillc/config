{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11009; cost = 1500; }
        { inherit (las.meta) name wg-public-key; listen = 11004; peer = 11009; cost = 170;  }
        { inherit (de.meta)  name wg-public-key; listen = 11006;               cost = 1500; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "208.99.48.169/24" "2602:fc1d:0:2:20e6:51ff:fe23:64f3/64" ];
        gateway = [ "208.99.48.1" "2602:fc1d:0:2::1" ];
    };
}