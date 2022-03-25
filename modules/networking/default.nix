{ config, pkgs, lib, ... }: with lib; {
    imports = [
        ./def
        ./wg-internal.nix
        ./babeld.nix
        ./frr
    ];
    services.resolved.enable = false;
    networking.useDHCP = false;
    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
    };
    net = {
        addresses = [
            { interface = "dmy11"; address = "${config.meta.igpv4}/32"; }
            { interface = "dmy11"; address = "${config.meta.igpv6}/128"; }
        ];
        routes = [
            { dst = "${config.meta.igpv4}/32";  interface = "dmy11"; proto = 114; table = 114; }
            { dst = "${config.meta.igpv6}/128"; interface = "dmy11"; proto = 114; table = 114; }
        ];
        tables = [ 114 ];
    };
}