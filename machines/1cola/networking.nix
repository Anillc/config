{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (hk.meta)     id name wg-public-key; listen = 16803; peer = 11001; cost = 400;  }
        { inherit (koishi.meta) id name wg-public-key; listen = 16804; peer = 11001; cost = 587;  }
        { inherit (lux.meta)    id name wg-public-key; listen = 16805; peer = 11001; cost = 2320; }
        { inherit (nnhr.meta)   id name wg-public-key; listen = 16806;               cost = 380;  }
        { inherit (r.meta)      id name wg-public-key; listen = 16808;               cost = 200;  }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        DHCP = "ipv4";
    };
    # TODO: fix this (optional endpoint)
    # wg.phone = {
    #     listen = 16810;
    #     publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
    # };
    # systemd.network.networks.phone = {
    #     matchConfig.Name = "phone";
    # };
    # bgp = {
    #     enable = true;
    #     extraBirdConfig = ''
    #         protocol static {
    #             route 10.11.1.4/32 via "phone";
    #             ipv4 {
    #                 table igp_v4;
    #             };
    #         }
    #         protocol static {
    #             route fd11:1::4/128 via "phone";
    #             ipv6 {
    #                 table igp_v6;
    #             };
    #         }
    #     '';
    # };
}