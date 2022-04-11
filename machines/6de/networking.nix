{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; peer = 11006; }
        { inherit (las.meta) name wg-public-key; peer = 11006; }
        { inherit (fmt.meta) name wg-public-key; peer = 11006; }
    ];
    networking.nameservers = [ "8.8.8.8" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens160";
        DHCP = "ipv4";
        address = [ "2a0f:9400:7a00:1111:8ba5::/48" "2a0f:9400:7a00:3333:f81c::1/64" ];
        gateway = [ "2a0f:9400:7a00::1" ];
    };
}