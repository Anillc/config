{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    china-ip = filter (x: x != "") (splitString "\n" (readFile "${pkgs.china-ip}/china_ip_list.txt"));
in {
    systemd.network.networks.flow = {
        matchConfig.Name = "flow";
        bridge = [ "br11" ];
    };
    containers.flow = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.flow = {};
        config = { ... }: {
            imports = [ ../../modules/networking/def/firewall.nix ];
            system.stateVersion = "22.05";
            documentation.enable = false;
            networking.firewall.enable = false;
            networking.interfaces.flow.ipv4.addresses = [{ address = "10.11.2.254"; prefixLength = 24; }];
            networking.defaultGateway  = { address = "10.11.2.3"; interface = "flow"; };
            boot.kernel.sysctl = {
                "net.ipv4.ip_forward" = 1;
                "net.ipv4.conf.all.rp_filter" = 0;
            };
            # TODO: 172.16.2.100
            systemd.services.flow = {
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                path = with pkgs; [ iproute2 ];
                script = concatStringsSep "\n" (flip map china-ip (x: ''
                    ip route add ${x} via 10.11.2.8
                '')) + ''
                    ip route add 10.0.0.0/8 via 10.11.2.8
                '';
            };
            environment.systemPackages = [ pkgs.mtr pkgs.dig pkgs.tcpdump ];
            firewall.extraInputRules = "ip saddr 0.0.0.0/32 accept";
            firewall.publicTCPPorts = [ 53 ];
            firewall.publicUDPPorts = [ 53 ];
            networking.nameservers = mkForce [ "127.0.0.1" ];
            networking.resolvconf.useLocalResolver = false;
            services.dnsmasq = {
                enable = true;
                servers = [ "/a/10.11.1.1" "8.8.8.8" ];
                resolveLocalQueries = false;
                extraConfig = ''
                    interface=flow
                    bogus-priv
                    # enable-ra
                    dhcp-range=10.11.2.128,10.11.2.253,24h
                    # dhcp-range=fdff:233::2,fdff:233::fff,ra-only
                '';
            };
        };
    };
}