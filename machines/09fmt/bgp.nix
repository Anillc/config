{ pkgs, ... }: {
    bgp = {
        enable = true;
        bgpTransit = {
            enable = true;
            asn = "7720";
            address = "2602:fc1d::1";
        };
        extraBirdConfig = ''
            protocol static {
                ipv6;
                route 2602:fc1d::/32 via "ens18";
            }
        '';
    };
}