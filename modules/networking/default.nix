{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    imports = [
        ./def
        ./bird
        ./frr
        ./wg.nix
    ];
    services.resolved.enable = false;
    networking.useDHCP = false;
    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
        "net.ipv6.conf.all.seg6_enabled" = 1;
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
                "${config.meta.externalV6}/128"
            ];
        };
    };
    systemd.services.srv6 = {
        after = [ "network-online.target" "systemd-networkd.service" ];
        partOf = [ "systemd-networkd.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ iproute2 ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
        };
        # 0x5200 -> 20992
        script = ''
            ip route add fd11:${toHexString (20992 + config.meta.id)}::1/128 encap seg6local action End dev dmy11
            ip route add fd11:${toHexString (20992 + config.meta.id)}::2/128 encap seg6local action End.DX4 nh4 ${config.meta.v4} dev dmy11
            ip route add fd11:${toHexString (20992 + config.meta.id)}::3/128 encap seg6local action End.DX6 nh6 ${config.meta.v6} dev dmy11
        '';
        postStop = ''
            ip route del fd11:${toHexString (20992 + config.meta.id)}::1/128 | true
            ip route del fd11:${toHexString (20992 + config.meta.id)}::2/128 | true
            ip route del fd11:${toHexString (20992 + config.meta.id)}::3/128 | true
        '';
    };
    firewall.extraPostroutingFilterRules = ''
        meta iifname br11 meta mark set 0x114
    '';
    bgp.extraBirdConfig = ''
        protocol static {
            route 2a0e:b107:1170::/48 reject;
            ipv6 {
                table bgp_v6;
            };
        }
        protocol static {
            route 2a0e:b107:1171::/48 reject;
            ipv6 {
                table bgp_v6;
            };
        }
        protocol static {
            route 2a0e:b107:df5::/48 reject;
            ipv6 {
                table bgp_v6;
            };
        }
        protocol static {
            route 2602:feda:da0::/44 reject;
            ipv6 {
                table bgp_v6;
            };
        }
        protocol static {
            route 2a0d:2587:8100::/41 reject;
            ipv6 {
                table bgp_v6;
            };
        }

        protocol static {
            route ${config.meta.v4}/32 via "dmy11";
            ipv4 {
                table igp_v4;
            };
        }
        protocol static {
            route ${config.meta.v6}/128 via "dmy11";
            ipv6 {
                table igp_v6;
            };
        }
        protocol static {
            route ${config.meta.externalV6}/128 via "dmy11";
            ipv6 {
                table igp_v6;
            };
        }
        # srv6
        protocol static {
            # 0x5200 -> 20992
            route fd11:${toHexString (20992 + config.meta.id)}::/32 reject;
            ipv6 {
                table igp_v6;
            };
        }
    '';
}