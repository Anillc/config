meta: { ... }: let
    machines = (import ./..).set;
in {
    bgp = {
        enable = true;
        connect = [ machines.shanghai machines.wuhan machines.school ];
        bgpSettings.dn42 = {
            v4 = "172.22.167.99";
            v6 = "fdc9:83c1:d0ce::3";
        };
        inherit meta;
    };
} 