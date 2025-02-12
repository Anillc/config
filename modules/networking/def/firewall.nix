{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.cfg.firewall;
in {
    options.cfg.firewall = {
        enableSourceFilter = mkOption {
            type = types.bool;
            description = "enable source filter";
            default = true;
        };
        publicTCPPorts = mkOption {
            type = types.listOf (types.oneOf [ types.port types.str ]);
            description = "public tcp port";
            default = [];
        };
        publicUDPPorts = mkOption {
            type = types.listOf (types.oneOf [ types.port types.str ]);
            description = "public udp port";
            default = [];
        };
        extraInputRules = mkOption {
            type = types.lines;
            description = "extraInputRules";
            default = "";
        };
        extraOutputRouteRules = mkOption {
            type = types.lines;
            description = "extraOutputRouteRules";
            default = "";
        };
        extraOutputRules = mkOption {
            type = types.lines;
            description = "extraOutputRules";
            default = "";
        };
        extraForwardRules = mkOption {
            type = types.lines;
            description = "extraForwardRules";
            default = "";
        };
        extraPreroutingFilterRules = mkOption {
            type = types.lines;
            description = "extraPreroutingFilterRules";
            default = "";
        };
        extraPreroutingRules = mkOption {
            type = types.lines;
            description = "extraPreroutingRules";
            default = "";
        };
        extraPostroutingRules = mkOption {
            type = types.lines;
            description = "extraPostroutingRules";
            default = "";
        };
        extraPostroutingFilterRules = mkOption {
            type = types.lines;
            description = "extraPostroutingFilterRules";
            default = "";
        };
    };
    config = {
        boot.blacklistedKernelModules = [ "ip_tables" ];
        environment.systemPackages = [ pkgs.nftables ];
        networking.firewall.enable = false;
        networking.nftables = let
            publicTCP = optionalString (length cfg.publicTCPPorts != 0) ''
                tcp dport { ${
                    concatStringsSep ", " (map toString cfg.publicTCPPorts)
                } } accept
            '';
            publicUDP = optionalString (length cfg.publicUDPPorts != 0) ''
                udp dport { ${
                    concatStringsSep ", " (map toString cfg.publicUDPPorts)
                } } accept
            '';
        in {
            enable = true;
            flushRuleset = false;
            tables.firewall = {
                name = "firewall";
                family = "inet";
                content = ''
                    define RESERVED_IP = {
                        0.0.0.0/8,       # RFC 1122 'this' network
                        10.0.0.0/8,      # RFC 1918 private space
                        100.64.0.0/10,   # RFC 6598 Carrier grade nat space
                        127.0.0.0/8,     # RFC 1122 localhost
                        169.254.0.0/16,  # RFC 3927 link local
                        172.16.0.0/12,   # RFC 1918 private space
                        192.0.2.0/24,    # RFC 5737 TEST-NET-1
                        192.88.99.0/24,  # RFC 7526 6to4 anycast relay
                        192.168.0.0/16,  # RFC 1918 private space
                        198.18.0.0/15,   # RFC 2544 benchmarking
                        198.51.100.0/24, # RFC 5737 TEST-NET-2
                        203.0.113.0/24,  # RFC 5737 TEST-NET-3
                        224.0.0.0/4,     # multicast
                        240.0.0.0/4,     # reserved
                    }
                    chain input {
                        type filter hook input priority filter; policy drop;
                        ct state { established, related } accept
                        meta iifname lo accept
                        ip protocol icmp accept
                        ip6 nexthdr icmpv6 accept
                        ip saddr 10.11.0.0/16 accept
                        ip6 saddr fd11::/16 accept
                        ${publicTCP}
                        ${publicUDP}
                        ${cfg.extraInputRules}
                    }
                    chain output-route {
                        type route hook output priority filter; policy accept;
                        ${cfg.extraOutputRouteRules}
                    }
                    chain output {
                        type filter hook output priority filter; policy accept;
                        ${cfg.extraOutputRules}
                    }
                    chain forward {
                        type filter hook forward priority filter; policy accept;
                        ${cfg.extraForwardRules}
                    }
                    chain prerouting-filter {
                        type filter hook prerouting priority mangle; policy accept;
                        ${cfg.extraPreroutingFilterRules}
                    }
                    chain prerouting {
                        type nat hook prerouting priority dstnat; policy accept;
                        ${cfg.extraPreroutingRules}
                    }
                    chain postrouting-filter {
                        type filter hook postrouting priority filter; policy accept;
                        ${cfg.extraPostroutingFilterRules}
                        meta mark 0x114 return
                        ${optionalString cfg.enableSourceFilter ''
                            ip  saddr 10.11.0.0/16 meta oifname "en*" drop
                            ip6 saddr fd11::/16    meta oifname "en*" drop
                        ''}
                    }
                    chain postrouting {
                        type nat hook postrouting priority srcnat; policy accept;
                        meta mark 0x114 masquerade
                        ${cfg.extraPostroutingRules}
                    }
                '';
            };
        };
    };
}