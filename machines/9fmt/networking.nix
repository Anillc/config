{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (tw.meta)     name wg-public-key; listen = 11002;               cost = 1300; }
        { inherit (koishi.meta) name wg-public-key; listen = 11004; peer = 11009; cost = 1500; }
        { inherit (hk.meta)     name wg-public-key; listen = 11003; peer = 11009; cost = 1500; }
        { inherit (lux.meta)    name wg-public-key; listen = 11005; peer = 11009; cost = 1420; }
        { inherit (nnhr.meta)   name wg-public-key; listen = 11006;               cost = 1600; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "208.99.48.169/24" "2602:fc1d:0:2:20e6:51ff:fe23:64f3/64" ];
        gateway = [ "208.99.48.1" "2602:fc1d:0:2::1" ];
    };
    systemd.network.networks.deploy.matchConfig.Name = "deploy";
    bgp = {
        enable = true;
        upstream = {
            enable = true;
            asn = "7720";
            address = "2602:fc1d:0:2::1";
            multihop = true;
        };
        extraBirdConfig = ''
            protocol static {
                route 10.11.1.3/32 via "deploy";
                ipv4 {
                    table igp_v4;
                };
            }
        '';
    };
}