{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11001; }
        { inherit (sh2.meta) name wg-public-key; listen = 11005; }
        { inherit (wh.meta)  name wg-public-key; listen = 11007; peer = 11001; }
        { inherit (jx.meta)  name wg-public-key; listen = 11008; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
}