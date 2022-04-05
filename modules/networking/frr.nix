{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.bgp;
    machines = import ../../machines lib;
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
        peers = mkOption {
            type = types.listOf (types.submodule {
                options = {
                    asn = mkOption {
                        type = types.str;
                        description = "asn";
                    };
                    address = mkOption {
                        type = types.str;
                        description = "address";
                    };
                };
            });
            description = "peers";
            default = [];
        };
    };
    config = mkIf cfg.enable {
        # bgp
        firewall.publicTCPPorts = [ 179 ];
        # vxlan
        firewall.internalUDPPorts = [ 4789 ];
        # TODO
        # systemd.services.frr-vxlan-setup = {
        #     after = [ "net-online.service" ];
        #     before = [ "net.service" ];
        #     partOf = [ "net.service" ];
        #     wantedBy = [ "net.service" "multi-user.target" ];
        #     restartIfChanged = true;
        #     path = with pkgs; [ iproute2 ];
        #     serviceConfig = {
        #         Type = "oneshot";
        #         RemainAfterExit = true;
        #     };
        #     script = ''
        #         ip link add vx11 type vxlan id 11 dstport 4789 local ${config.meta.v4} nolearning
        #         ip link set vx11 up
        #         ip link add br11 type bridge
        #         ip link set br11 up
        #         ip link set vx11 master br11
        #     '';
        #     postStop = ''
        #         ip link del br11 || true
        #         ip link del vx11 || true
        #     '';
        # };
        services.frr-override = {
            zebra = {
                enable = true;
                config = ''
                    route-map SET_SRC permit 10
                     set src 2602:feda:da0::${toHexString config.meta.id}
                    ip   nht resolve-via-default
                    ipv6 nht resolve-via-default
                    ipv6 protocol bgp route-map SET_SRC
                '';
            };
            static = {
                enable = true;
                config = ''
                    ipv6 route 2a0e:b107:1170::/48 reject 
                    ipv6 route 2a0e:b107:1171::/48 reject 
                    ipv6 route 2a0e:b107:df5::/48  reject 
                    ipv6 route 2602:feda:da0::/44  reject 
                    ipv6 route 2a0d:2587:8100::/41 reject 
                '';
            };
            bgp = {
                enable = true;
                extraOptions = "-M rpki";
                config = ''
                    ipv6 prefix-list NETWORK seq 1 permit 2a0e:b107:1170::/48
                    ipv6 prefix-list NETWORK seq 2 permit 2a0e:b107:1171::/48
                    ipv6 prefix-list NETWORK seq 3 permit 2a0e:b107:df5::/48
                    ipv6 prefix-list NETWORK seq 4 permit 2602:feda:da0::/44
                    ipv6 prefix-list NETWORK seq 5 permit 2a0d:2587:8100::/41
                    ipv6 prefix-list NETWORK seq 6 deny any

                    ipv6 prefix-list BOGON_v6 seq 1  deny ::/8 le 128
                    ipv6 prefix-list BOGON_v6 seq 2  deny 100::/64 le 128
                    ipv6 prefix-list BOGON_v6 seq 3  deny 2001:2::/48 le 128
                    ipv6 prefix-list BOGON_v6 seq 4  deny 2001:10::/28 le 128
                    ipv6 prefix-list BOGON_v6 seq 5  deny 2001:db8::/32 le 128
                    ipv6 prefix-list BOGON_v6 seq 6  deny 2002::/16 le 128
                    ipv6 prefix-list BOGON_v6 seq 7  deny 3ffe::/16 le 128
                    ipv6 prefix-list BOGON_v6 seq 8  deny fc00::/7 le 128
                    ipv6 prefix-list BOGON_v6 seq 9  deny fe80::/10 le 128
                    ipv6 prefix-list BOGON_v6 seq 10 deny fec0::/10 le 128
                    ipv6 prefix-list BOGON_v6 seq 11 deny ff00::/8 le 128
                    ipv6 prefix-list BOGON_v6 seq 12 deny ::/0 ge 49 le 128
                    ipv6 prefix-list BOGON_v6 seq 13 permit any

                    bgp as-path access-list BOGON_ASN seq 1 deny 23456
                    bgp as-path access-list BOGON_ASN seq 2 deny 64496-131071
                    bgp as-path access-list BOGON_ASN seq 3 deny 4200000000-4294967295
                    bgp as-path access-list BOGON_ASN seq 4 permit .*

                    rpki
                     rpki cache rtr.rpki.cloudflare.com 8282 preference 1
                     exit
                    
                    route-map IBGP_IN permit 10
                     set local-preference 50
                    route-map IBGP_OUT permit 10
                     ! ibgp won't send neighbor's routes to other neighbors
                     ${optionalString cfg.upstream.enable "set as-path prepend ${cfg.upstream.asn}"}

                    route-map UPSTREAM_IN deny 10
                    route-map UPSTREAM_OUT permit 10
                     match ipv6 address prefix-list NETWORK

                    route-map PEERS_IN permit 10
                     match as-path BOGON_ASN
                    route-map PEERS_IN permit 15
                     match ipv6 address prefix-list BOGON_v6
                    route-map PEERS_IN deny 20
                     match rpki invalid
                    route-map PEERS_OUT permit 10
                     match ipv6 address prefix-list NETWORK

                    router bgp 142055
                     bgp router-id ${config.meta.v4}
                     bgp graceful-restart
                     no bgp default ipv4-unicast
                     no bgp default ipv6-unicast
                     ! ibgp
                     neighbor ibgp peer-group
                     neighbor ibgp capability dynamic
                     neighbor ibgp remote-as 142055
                     neighbor ibgp next-hop-self
                    ${concatStrings (map (x:
                        " neighbor ${x.meta.v4} peer-group ibgp\n"
                    ) (filter (x: x.meta.id != config.meta.id) machines.list))}
                     ! ebgp upstream
                     neighbor upstream peer-group
                     neighbor upstream capability dynamic
                     neighbor upstream next-hop-self
                     ${optionalString cfg.upstream.multihop "neighbor upstream ebgp-multihop"}
                     ${optionalString (cfg.upstream.password != null) "neighbor upstream password ${cfg.upstream.password}"}
                    ${optionalString cfg.upstream.enable (
                        " neighbor ${cfg.upstream.address} peer-group upstream\n" +
                        " neighbor ${cfg.upstream.address} remote-as ${cfg.upstream.asn}"
                    )}
                     ! ebgp peers
                     neighbor peers peer-group
                     neighbor peers capability dynamic
                     neighbor peers next-hop-self
                    ${concatStrings (map (x:
                        " neighbor ${x.address} peer-group peers\n" +
                        " neighbor ${x.address} remote-as ${x.asn}\n"
                    ) cfg.peers)}
                     address-family l2vpn evpn
                      neighbor ibgp activate
                      advertise-all-vni
                     exit-address-family
                     address-family ipv6 unicast
                      ! redistribute prefixes
                      redistribute static
                      ${optionalString cfg.upstream.enable "network ::/0"}
                      neighbor ibgp activate
                      neighbor ibgp soft-reconfiguration inbound
                      neighbor ibgp route-map IBGP_IN  in
                      neighbor ibgp route-map IBGP_OUT out
                      neighbor upstream activate
                      neighbor upstream soft-reconfiguration inbound
                      neighbor upstream route-map UPSTREAM_IN  in
                      neighbor upstream route-map UPSTREAM_OUT out
                      neighbor peers activate
                      neighbor peers soft-reconfiguration inbound
                      neighbor peers route-map PEERS_IN  in
                      neighbor peers route-map PEERS_OUT out
                     exit-address-family
                '';
            };
        };
    };
}