meta: { config, ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        connect = [ machines.shanghai ];
        bgpSettings = {
            dn42.v4 = "172.22.167.106";
            dn42.v6 = "fdc9:83c1:d0ce::10";
        };
        inherit meta;
    };
} 