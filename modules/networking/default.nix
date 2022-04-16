{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ../../machines lib;
in {
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
    environment.etc."systemd/networkd.conf".text = ''
        [Network]
        ManageForeignRoutes=no
    '';
    systemd.network = mkMerge ([
        { enable = true; }
        {
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
        }
    ] ++ (flip map machines.list (x: {
        netdevs."g${x.meta.name}" = {
            netdevConfig = {
                Name = "g${x.meta.name}";
                Kind = "gre";
            };
            tunnelConfig = {
                Local = config.meta.v4;
                Remote = x.meta.v4;
                Independent = true;
            };
        };
        networks."g${x.meta.name}" = {
            matchConfig.Name = "g${x.meta.name}";
            addresses = [{
                addressConfig = {
                    Address = "10.11.2.${toString config.meta.id}/32";
                    Peer = "10.11.2.${toString x.meta.id}/32";
                };
            }];
        };
    })));
}