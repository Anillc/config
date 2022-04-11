{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta)  name wg-public-key; listen = 11001; peer = 11003; }
        { inherit (las.meta) name wg-public-key; listen = 11004; peer = 11003; }
        { inherit (de.meta)  name wg-public-key; listen = 11006; }
        { inherit (fmt.meta) name wg-public-key; listen = 11009; peer = 11003; }
    ];
    networking.nameservers = [ "8.8.8.8" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        address = [ "103.152.35.32/24" "2406:4440::32/64" ];
        gateway = [ "103.152.35.254" "2406:4440::1" ];
    };
}