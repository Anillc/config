{ config, pkgs, lib, ... }: with lib; {
    imports = [
        ./def
        ./wg-internal.nix
        ./babeld.nix
    ];
    services.resolved.enable = false;
    networking.useDHCP = false;
    boot.kernel.sysctl = mkForce {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
    };
    net = {
        addresses = [
            { interface = "dummy2526"; address = "${config.meta.v4}/32"; }
            { interface = "dummy2526"; address = "${config.meta.v6}/128"; }
            { interface = "dummy2526"; address = "2602:feda:da0::${config.meta.id}/128"; }
        ];
        routes = [
            { dst = "${config.meta.v4}/32";                 interface = "dummy2526"; proto = 114; table = 114; }
            { dst = "${config.meta.v6}/128";                interface = "dummy2526"; proto = 114; table = 114; }
            { dst = "2602:feda:da0::${config.meta.id}/128"; interface = "dummy2526"; proto = 114; table = 114; }
        ];
        tables = [ 114 ];
    };
}