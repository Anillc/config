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
        extraOutRules = mkOption {
            type = types.lines;
            description = "extraOutRules";
            default = "";
        };
        extraForwardRules = mkOption {
            type = types.lines;
            description = "extraForwardRules";
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
                    chain output {
                        type filter hook output priority filter; policy accept;
                        ${cfg.extraOutRules}
                    }
                    chain forward {
                        type filter hook forward priority filter; policy accept;
                        ${cfg.extraForwardRules}
                    }
                    chain prerouting {
                        type nat hook prerouting priority dstnat; policy accept;
                        ${cfg.extraPreroutingRules}
                    }
                    chain postrouting-filter {
                        type filter hook postrouting priority filter; policy accept;
                        ${cfg.extraPostroutingFilterRules}
                        meta mark 0x114 accept
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