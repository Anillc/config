{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    cfg = config.flow;
    china-ip = filter (x: x != "") (splitString "\n" (readFile "${inputs.china-ip}/china.txt"));
in {
    options.flow.enable = mkEnableOption "flow";
    config = mkIf cfg.enable {
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
                        port=0
                        interface=flow
                        bogus-priv
                        dhcp-range=10.11.2.128,10.11.2.253,24h
                        dhcp-option=option:dns-server,10.11.2.254
                    '';
                };
                services.smartdns = {
                    enable = true;
                    settings = {
                        bind = ":53";
                        bind-tcp = ":53";
                        force-AAAA-SOA = "yes";
                        speed-check-mode = "none";
                        nameserver = "/a/an";
                        conf-file = [
                            "${pkgs.dnsmasq-china-list}/accelerated-domains.china.smartdns.conf"
                            "${pkgs.dnsmasq-china-list}/apple.china.smartdns.conf"
                        ];
                        server = [
                            "8.8.8.8"
                            "1.2.4.8 -group domestic -exclude-default-group"
                            "210.2.4.8 -group domestic -exclude-default-group"
                            "10.11.1.1 -group an -exclude-default-group"
                        ];
                        server-tcp = [ "208.67.220.220:443" ];
                        server-https = [
                            "https://146.112.41.2/dns-query"
                            "https://101.101.101.101/dns-query"
                        ];
                        server-tls = [
                            "1.12.12.12:853 -group domestic -exclude-default-group"
                            "120.53.53.53:853 -group domestic -exclude-default-group"
                            "223.5.5.5:853 -group domestic -exclude-default-group"
                            "223.6.6.6:853 -group domestic -exclude-default-group"
                            "114.114.114.114 -group domestic -exclude-default-group"
                            "114.114.115.115 -group domestic -exclude-default-group"
                        ];
                    };
                };
            };
        };
    };
}