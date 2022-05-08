{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; listen = 11003; peer = 11001; cost = 400; }
        { inherit (sh2.meta) name wg-public-key; listen = 11005;               cost = 80;  }
        { inherit (wh.meta)  name wg-public-key; listen = 11007; peer = 11001; cost = 200; }
        { inherit (jx.meta)  name wg-public-key; listen = 11008;               cost = 200; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens5";
        DHCP = "ipv4";
    };
    wg.phone = {
        listen = 11451;
        publicKey = "Pm7l051569YlVKkaCItUR8TmeAp7m6od3RhSkOGPriA=";
    };
    wg.maiko = {
        listen = 11452;
        publicKey = "F+FfMqX4hMESHceIC8vPQ7aZXzaeDk/BTG/GD0RgCGQ=";
    };
    systemd.network.networks.phone = {
        matchConfig.Name = "phone";
    };
    systemd.network.networks.maiko = {
        matchConfig.Name = "maiko";
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
        protocol static {
            route 10.11.1.5/32 via "maiko";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    clash.enable = true;
}