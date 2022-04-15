{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    imports = [
        ./def
        ./bird
        ./wg.nix
    ];
    services.resolved.enable = false;
    networking.useDHCP = false;
    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
    };
    systemd.network = {
        enable = true;
        netdevs.dmy11.netdevConfig = {
            Name = "dmy11";
            Kind = "dummy";
        };
        networks.dmy11 = {
            matchConfig.Name = "dmy11";
            address = [
                "${config.meta.v4}/32"
                "${config.meta.v6}/128"
                "2602:feda:da0::${toHexString config.meta.id}/128"
            ];
            routes = [
                { routeConfig = { Destination = "${config.meta.v4}/32";  Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "${config.meta.v6}/128"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "2602:feda:da0::${toHexString config.meta.id}/128"; Table = 114; Protocol = 114; }; }
            ];
            routingPolicyRules = [{
                routingPolicyRuleConfig = {
                    Family = "both";
                    Table = "114";
                };
            }];
        };
    };
}