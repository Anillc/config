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
                "${config.cfg.meta.v4}/32"
                "${config.cfg.meta.v6}/128"
            ];
        };
    };
    services.bird2.config = ''
        protocol static {
            route ${config.cfg.meta.v4}/32 via "dmy11";
            ipv4 {
                table igp_v4;
            };
        }
        protocol static {
            route ${config.cfg.meta.v6}/128 via "dmy11";
            ipv6 {
                table igp_v6;
            };
        }
    '';
}