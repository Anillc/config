{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (product.meta) id name wg-public-key; listen = 16802;               cost = 630;  }
        { inherit (sum.meta)     id name wg-public-key; listen = 16803; peer = 11001; cost = 560;  }
        { inherit (lux.meta)     id name wg-public-key; listen = 16805; peer = 11001; cost = 2320; }
        { inherit (r.meta)       id name wg-public-key; listen = 16808;               cost = 200;  }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens192";
        DHCP = "ipv4";
    };
    cfg.wg.backup = {
        endpoint = "forum.koishi.xyz:38170";
        publicKey = "Deqb6JR7Z4AI4eg+IMGjr56Gf4MgvFwZ5MfpLcjz3kg=";
    };
    systemd.network.networks.backup = {
        matchConfig.Name = "backup";
        networkConfig.Address = "fe80::2/64";
    };
    # allow restic requests
    cfg.firewall.extraInputRules = ''
        iifname "backup" tcp dport 8081 accept
    '';
    # TODO: fix this (optional endpoint)
    # cfg.wg.phone = {
    #     listen = 16810;
    #     publicKey = "lZENdaGTl/kRnclal+Bbkn9LGXlYQ9K5P1hO92WTYU8=";
    # };
}