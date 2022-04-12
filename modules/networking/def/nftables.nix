{ config, pkgs, lib, ... }: with lib; let
    cfg = config.firewall;
in {
    options.firewall = {
        enableSourceFilter = mkOption {
            type = types.bool;
            description = "enable source filter";
            default = true;
        };
        internalTCPPorts = mkOption {
            type = types.listOf types.port;
            description = "internal tcp port";
            default = [];
        };
        internalUDPPorts = mkOption {
            type = types.listOf types.port;
            description = "internal udp port";
            default = [];
        };
        publicTCPPorts = mkOption {
            type = types.listOf types.port;
            description = "public tcp port";
            default = [];
        };
        publicUDPPorts = mkOption {
            type = types.listOf types.port;
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
    };
    config = {
        networking.firewall.enable = false;
        networking.nftables = let
            internalTCP = optionalString (builtins.length cfg.internalTCPPorts != 0) ''
                ip saddr 10.11.0.0/16 tcp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalTCPPorts)
                } } accept
                ip6 saddr fd11::/16 tcp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalTCPPorts)
                } } accept
            '';
            internalUDP = optionalString (builtins.length cfg.internalUDPPorts != 0) ''
                ip saddr 10.11.0.0/16 udp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalUDPPorts)
                } } accept
                ip6 saddr fd11::/16 udp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalUDPPorts)
                } } accept
            '';
            publicTCP = optionalString (builtins.length cfg.publicTCPPorts != 0) ''
                tcp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.publicTCPPorts)
                } } accept
            '';
            publicUDP = optionalString (builtins.length cfg.publicUDPPorts != 0) ''
                udp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.publicUDPPorts)
                } } accept
            '';
        in {
            enable = true;
            ruleset = ''
                flush ruleset
                table inet firewall {
                    chain input {
                        type filter hook input priority filter; policy drop;
                        ct state { established, related } accept
                        meta iifname lo accept
                        ip protocol icmp accept
                        ip6 nexthdr icmpv6 accept
                        ${internalTCP}
                        ${internalUDP}
                        ${publicTCP}
                        ${publicUDP}
                        ${cfg.extraInputRules}
                    }
                    chain output {
                        type filter hook output priority filter; policy accept;
                        ${optionalString cfg.enableSourceFilter ''
                            ip  saddr 10.11.0.0/16 oifname "en*" reject
                            ip6 saddr fd11::/16    oifname "en*" reject
                        ''}
                        ${cfg.extraOutRules}
                    }
                    chain forward {
                        type filter hook forward priority filter; policy accept;
                        ${optionalString cfg.enableSourceFilter ''
                            ip  saddr 10.11.0.0/16 oifname "en*" reject
                            ip6 saddr fd11::/16    oifname "en*" reject
                        ''}
                        ${cfg.extraForwardRules}
                    }
                    chain prerouting {
                        type nat hook prerouting priority dstnat; policy accept;
                        ${cfg.extraPreroutingRules}
                    }
                    chain postrouting {
                        type nat hook postrouting priority srcnat; policy accept;
                        ${cfg.extraPostroutingRules}
                    }
                }
            '';
        };
    };
}