{ config, pkgs, lib, ... }: with lib; let
    cfg = config.firewall;
in {
    options.firewall = {
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
        extraForwardRules = mkOption {
            type = types.lines;
            description = "extraForwardRules";
            default = "";
        };
        extraNatRules = mkOption {
            type = types.lines;
            description = "extraNatRules";
            default = "";
        };
        extraPreroutingRules = mkOption {
            type = types.lines;
            description = "extraPreroutingRules";
            default = "";
        };
    };
    config = {
        networking.firewall.enable = false;
        systemd.services.nftables = {
            wants = lib.mkForce [ "network-online.target" ];
            before = lib.mkForce [ "network-online.target" ];
            after = [ "systemd-networkd.service" ];
        };
        networking.nftables = let
            internalTCP = optionalString (builtins.length cfg.internalTCPPorts != 0) ''
                ip saddr { 10.127.20.0/24, 172.22.167.96/27 } tcp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalTCPPorts)
                } } accept
                ip6 saddr { fd10:127:cc::/48, fdc9:83c1:d0ce::/48 } tcp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalTCPPorts)
                } } accept
            '';
            internalUDP = optionalString (builtins.length cfg.internalUDPPorts != 0) ''
                ip saddr { 10.127.20.0/24, 172.22.167.96/27 } udp dport { ${
                    pkgs.lib.strings.concatStringsSep ", " (builtins.map builtins.toString cfg.internalUDPPorts)
                } } accept
                ip6 saddr { fd10:127:cc::/48, fdc9:83c1:d0ce::/48 } udp dport { ${
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
                        type filter hook input priority 0; policy drop;
                        ct state { established, related } accept
                        meta iif lo accept
                        ip protocol icmp accept
                        ip6 nexthdr icmpv6 accept
                        ${internalTCP}
                        ${internalUDP}
                        ${publicTCP}
                        ${publicUDP}
                        ${cfg.extraInputRules}
                    }
                    chain output {
                        type filter hook output priority 0; policy accept;
                    }
                    chain forward {
                        type filter hook forward priority 0; policy accept;
                        ${cfg.extraForwardRules}
                    }
                    chain prerouting {
                        type nat hook prerouting priority -100; policy accept;
                        ${cfg.extraPreroutingRules}
                    }
                    chain postrouting {
                        type nat hook postrouting priority 100; policy accept;
                        ${cfg.extraNatRules}
                    }
                }
            '';
        };
    };
}