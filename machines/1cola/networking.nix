{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)     name wg-public-key; listen = 16803; peer = 11001; cost = 100;  } # TODO: 400
        { inherit (koishi.meta) name wg-public-key; listen = 16804; peer = 11001; cost = 587;  }
        { inherit (lux.meta)    name wg-public-key; listen = 16805; peer = 11001; cost = 2320; }
        { inherit (nnhr.meta)   name wg-public-key; listen = 16806;               cost = 380;  }
        { inherit (r.meta)      name wg-public-key; listen = 16808;               cost = 200;  }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        DHCP = "ipv4";
    };
    wg.phone = {
        listen = 16810;
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
}