{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11002; }
        { inherit (las.meta) name wg-public-key; listen = 11004; peer = 11002; }
        { inherit (de.meta)  name wg-public-key; listen = 11006; }
    ];
    networking.nameservers = [ "8.8.8.8" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "enp1s0";
        DHCP = "yes";
    };
}