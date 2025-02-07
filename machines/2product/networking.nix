{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta)   id name wg-public-key; peer = 16802; cost = 630;  }
        { inherit (hk.meta)     id name wg-public-key; peer = 11002; cost = 1000; }
        { inherit (koishi.meta) id name wg-public-key; peer = 11002; cost = 690;  }
        { inherit (lux.meta)    id name wg-public-key; peer = 11002; cost = 4000; }
    ];
    cfg.firewall.enableSourceFilter = false;
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        DHCP = "yes";
    };
    systemd.network.networks.ens20 = {
        matchConfig.Name = "ens20";
        networkConfig.Address = [ config.cfg.meta.v4 "fe80::2/64" ];
    };
    services.bird2.config = ''
        protocol static {
            route 10.11.1.3/32 via fe80::1%ens20 { krt_prefsrc = ${config.cfg.meta.v4}; };
            ipv4 {
                table igp_v4;
            };
        }
    '';
    cfg.access = {
        enable = true;
        interface = "ens19";
        ip = "10.11.1.4";
    };
}
