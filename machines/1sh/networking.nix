{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)     name wg-public-key; listen = 11003; peer = 11001; cost = 100; } # TODO: 400
        { inherit (koishi.meta) name wg-public-key; listen = 11004; peer = 11001; cost = 587; }
        { inherit (wh.meta)     name wg-public-key; listen = 11007; peer = 11001; cost = 200; }
        { inherit (jx.meta)     name wg-public-key; listen = 11008;               cost = 200; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
    wg.phone = {
        listen = 11451;
        publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
    };
    systemd.network.networks.phone = {
        matchConfig.Name = "phone";
    };
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.11.1.4/32 via "phone";
            ipv4 {
                table igp_v4;
            };
        }
        protocol static {
            route fd11:1::4/128 via "phone";
            ipv6 {
                table igp_v6;
            };
        }
    '';
    clash.enable = true;
}