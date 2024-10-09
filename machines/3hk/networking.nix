{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta)   id name wg-public-key; listen = 11001; peer = 16803; cost = 400;  }
        { inherit (tw.meta)     id name wg-public-key; listen = 11002;               cost = 1900; }
        { inherit (koishi.meta) id name wg-public-key; listen = 11004; peer = 11003; cost = 21;   }
        { inherit (lux.meta)    id name wg-public-key; listen = 11005; peer = 11003; cost = 1870; }
        { inherit (nnhr.meta)   id name wg-public-key; listen = 11006;               cost = 110;   }
        { inherit (r.meta)      id name wg-public-key; listen = 11008;               cost = 400;  }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        address = [ "103.152.35.32/24" "2406:4440::32/64" ];
        gateway = [ "103.152.35.254" "2406:4440::1" ];
    };
    bgp = {
        enable = true;
        upstream = {
            enable = true;
            asn = "38008";
            address = "2406:4440::1";
        };
        peers.aperix = { # APERIX
            asn = "38008";
            address = "2406:4440::100";
        };
    };
}