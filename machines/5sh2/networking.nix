{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta) name wg-public-key; peer = 11005; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "192.168.1.110/24" ];
        gateway = [ "192.168.1.1" ];
    };
}