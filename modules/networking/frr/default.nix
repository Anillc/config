{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.bgp;
    machines = import ../../../machines lib;
in {
    options.bgp = {
        enable = mkEnableOption "enable bgp";
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
            '';
            postStop = ''
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
                    ip   nht resolve-via-default
                    ipv6 nht resolve-via-default
                '';
            };
            bgp = {
                enable = true;
                config = ''
                    router bgp 142055
                        bgp router-id ${config.meta.igpv4}
                        no bgp default ipv4-unicast
                        no bgp default ipv6-unicast
                        neighbor ipeers peer-group
                        neighbor ipeers remote-as 142055
                        ${concatStrings (map (x:
                            "neighbor ${x.meta.igpv4} peer-group ipeers\n    ") (filter (x: x.meta.id != config.meta.id) machines.list))}
                        address-family l2vpn evpn
                            neighbor ipeers activate
                            advertise-all-vni
                        exit-address-family
                '';
            };
        };
    };
}