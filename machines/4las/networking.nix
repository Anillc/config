{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (jp.meta)  name wg-public-key; listen = 11002; peer = 11004; }
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11004; }
        { inherit (de.meta)  name wg-public-key; listen = 11006; }
        { inherit (fmt.meta) name wg-public-key; listen = 11009; peer = 11004; }
    ];
    networking.nameservers = [ "8.8.8.8" ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens3";
        DHCP = "ipv4";
        address = [ "2605:6400:20:677::/48" ];
        gateway = [ "2605:6400:20::1" ];
        routes = [{
            routeConfig = {
                Destination = "2605:6400:ffff::2/128";
                PreferredSource = "2605:6400:20:677::";
                Gateway = "2605:6400:20::1";
            };
        }];
    };
}