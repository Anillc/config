{ config, pkgs, lib, ... }:

with builtins;
with lib;
let
    machines = import ../../../machines lib;
in {
    systemd.network = {
        # TODO: https://github.com/NixOS/nixpkgs/pull/170632
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
    services.frr = {
        zebra.enable = true;
        bgp = {
            enable = true;
            extraOptions = [ "-M rpki" ];
            config = ''
                router bgp 142055
                 bgp router-id ${config.meta.v4}
                 no bgp default ipv4-unicast
                 no bgp default ipv6-unicast
                 neighbor ipeers peer-group
                 neighbor ipeers remote-as 142055
                 ${concatStringsSep "\n" (map
                     (x: " neighbor ${x.meta.v4} peer-group ipeers")
                 (filter (x: x.meta.id != config.meta.id) machines.list))}
                 address-family l2vpn evpn
                  neighbor ipeers activate
                  advertise-all-vni
                 exit-address-family
                 address-family ipv4 vpn
                  neighbor ipeers activate
                 exit-address-family
                 address-family ipv6 vpn
                  neighbor ipeers activate
                 exit-address-family
                exit
                router bgp 142055 vrf seg
                 bgp router-id ${config.meta.v4}
                 no bgp ebgp-requires-policy
                 no bgp default ipv4-unicast
                 address-family ipv4 unicast
                  redistribute connected
                  rd vpn export ${config.meta.v4}:114
                  rt vpn both 142055:114
                  sid vpn export auto
                  export vpn
                  import vpn
                 exit-address-family
                 address-family ipv6 unicast
                  redistribute connected
                  rd vpn export ${config.meta.v4}:114
                  rt vpn both 142055:114
                  sid vpn export auto
                  export vpn
                  import vpn
                 exit-address-family
                exit
            '';
        };
    };
}