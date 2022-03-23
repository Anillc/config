{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.bgp;
    machines = import ../../../machines lib;
in {
    options.bgp = {
        enable = mkEnableOption "enable bgp";
        upstream = {
            enable = mkEnableOption "enable transit";
            asn = mkOption {
                type = types.str;
                description = "asn";
            };
            address = mkOption {
                type = types.str;
                description = "address";
            };
            password = mkOption {
                type = types.nullOr types.str;
                description = "password";
                default = null;
            };
            multihop = mkOption {
                type = types.bool;
                description = "multihop";
                default = false;
            };
        };
    };
    config = mkIf cfg.enable {
        # bgp
        firewall.publicTCPPorts = [ 179 ];
        # vxlan
        firewall.internalUDPPorts = [ 4789 ];
        systemd.services.frr-vxlan-setup = {
            after = [ "net-online.service" ];
            before = [ "net.service" ];
            partOf = [ "net.service" ];
            wantedBy = [ "net.service" "multi-user.target" ];
            restartIfChanged = true;
            path = with pkgs; [ iproute2 ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
            };
            script = ''
                ip link add vx11 type vxlan id 11 dstport 4789 local ${config.meta.igpv4} nolearning
                ip link set vx11 up
                ip link add br11 type bridge
                ip link set br11 up
                ip link set vx11 master br11
                ip address add ${config.meta.v4}/22 dev br11
                ip address add ${config.meta.v6}/32 dev br11

                ip address add 2602:feda:da0::${toHexString config.meta.id}/48 dev br11
            '';
            postStop = ''
                ip address del 2602:feda:da0::${toHexString config.meta.id}/48 dev br11
                ip address del ${config.meta.v4}/22 dev br11
                ip address del ${config.meta.v6}/32 dev br11
                ip link del br11 || true
                ip link del vx11 || true
            '';
        };
        services.frr = {
            zebra = {
                enable = true;
                config = ''
                    route-map SET_SRC permit 10
                     set src 2602:feda:da0::${toHexString config.meta.id}
                    ip   nht resolve-via-default
                    ipv6 nht resolve-via-default
                    ipv6 protocol bgp route-map SET_SRC
                ''; # TODO
            };
            static = {
                enable = true;
                config = ''
                    ipv6 route 2a0e:b107:1170::/48 reject 
                    ipv6 route 2a0e:b107:1171::/48 reject 
                    ipv6 route 2a0e:b107:df5::/48  reject 
                    ipv6 route 2602:feda:da0::/44  reject 
                    ipv6 route 2a0d:2587:8100::/41 reject 
                    ipv6 prefix-list NETWORK seq 1 permit 2a0e:b107:1170::/48
                    ipv6 prefix-list NETWORK seq 2 permit 2a0e:b107:1171::/48
                    ipv6 prefix-list NETWORK seq 3 permit 2a0e:b107:df5::/48
                    ipv6 prefix-list NETWORK seq 4 permit 2602:feda:da0::/44
                    ipv6 prefix-list NETWORK seq 5 permit 2a0d:2587:8100::/41
                    ipv6 prefix-list NETWORK seq 6 deny any
                '';
            };
            bgp = {
                enable = true;
                config = ''
                    route-map UPSTREAM_IN permit 10
                    route-map UPSTREAM_OUT permit 10
                     match ipv6 address prefix-list NETWORK

                    route-map IBGP_IN permit 10
                     set local-preference 50
                    route-map IBGP_OUT permit 10
                     set ip next-hop ${config.meta.v4}
                     set ipv6 next-hop global ${config.meta.v6}

                    router bgp 142055
                     bgp router-id ${config.meta.igpv4}
                     no bgp default ipv4-unicast
                     no bgp default ipv6-unicast
                     ! ibgp
                     neighbor ibgp peer-group
                     neighbor ibgp capability dynamic
                     neighbor ibgp remote-as 142055
                    ${concatStrings (map (x:
                        " neighbor ${x.meta.igpv4} peer-group ibgp\n"
                    ) (filter (x: x.meta.id != config.meta.id) machines.list))}
                     ! ebgp
                     neighbor upstream peer-group
                     neighbor upstream capability dynamic
                     neighbor upstream prefix-list UPSTREAM_OUT out
                     ${optionalString cfg.upstream.multihop "neighbor upstream ebgp-multihop"}
                     ${optionalString (cfg.upstream.password != null) "neighbor upstream password ${cfg.upstream.password}"}
                    ${optionalString cfg.upstream.enable (
                        " neighbor ${cfg.upstream.address} peer-group upstream\n" +
                        " neighbor ${cfg.upstream.address} remote-as ${cfg.upstream.asn}"
                    )}
                     address-family l2vpn evpn
                      neighbor ibgp activate
                      advertise-all-vni
                     exit-address-family
                     address-family ipv6 unicast
                      ! redistribute prefixes
                      redistribute static
                      neighbor ibgp activate
                      neighbor ibgp route-map IBGP_IN  in
                      neighbor ibgp route-map IBGP_OUT out
                    ${optionalString cfg.upstream.enable (
                        "  neighbor upstream activate\n" +
                        "  neighbor upstream route-map UPSTREAM_IN  in\n" +
                        "  neighbor upstream route-map UPSTREAM_OUT out"
                    )}
                     exit-address-family
                '';
            };
        };
    };
}