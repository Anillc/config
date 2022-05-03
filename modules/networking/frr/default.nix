{ config, pkgs, lib, ... }:

with builtins;
with lib;
let
    machines = import ../../../machines lib;
in {
    imports = [ ./frr-override.nix ];
    systemd.network = {
        units."evpn.netdev".text = ''
            [NetDev]
            Kind=vxlan
            Name=evpn
            [VXLAN]
            VNI=11
            Local=${config.meta.v4}
            Independent=yes
        '';
        netdevs.br11.netdevConfig = {
            Name = "br11";
            Kind = "bridge";
        };
        networks.evpn = {
            matchConfig.Name = "evpn";
            bridge = [ "br11" ];
        };
        networks.br11 = {
            matchConfig.Name = "br11";
            address = [ "10.11.2.${toString config.meta.id}/24" ];
        };
    };
    services.frr-override = {
        zebra = {
            enable = true;
            config = ''
                ip   nht resolve-via-default
                ipv6 nht resolve-via-default
            '';
        };
        bgp = {
            enable = true;
            extraOptions = "-M rpki";
            config = ''
                router bgp 142055
                 bgp router-id ${config.meta.v4}
                 no bgp default ipv4-unicast
                 no bgp default ipv6-unicast
                 neighbor ipeers peer-group
                 neighbor ipeers remote-as 142055
                 !neighbor ipeers port 180
                 ${concatStringsSep "\n" (map
                     (x: " neighbor ${x.meta.v4} peer-group ipeers")
                 (filter (x: x.meta.id != config.meta.id) machines.list))}
                 address-family l2vpn evpn
                  neighbor ipeers activate
                  advertise-all-vni
                 exit-address-family
            '';
        };
    };
}