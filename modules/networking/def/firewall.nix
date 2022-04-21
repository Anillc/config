{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    cfg = config.firewall;
in {
    options.firewall = {
        enableSourceFilter = mkOption {
            type = types.bool;
            description = "enable source filter";
            default = true;
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
        boot.blacklistedKernelModules = [ "ip_tables" ];
        environment.systemPackages = [ pkgs.nftables ];
        networking.firewall.enable = false;
        systemd.services.firewall = let
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
            script = pkgs.writeScript "nftables-rule" ''
                #!${pkgs.nftables}/bin/nft -f
                table inet firewall {
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
                        ${optionalString cfg.enableSourceFilter ''
                            ip  saddr 10.11.0.0/16 meta oifname "en*" reject
                            ip6 saddr fd11::/16    meta oifname "en*" reject
                        ''}
                        ${cfg.extraOutRules}
                    }
                    chain forward {
                        type filter hook forward priority filter; policy accept;
                        ${optionalString cfg.enableSourceFilter ''
                            ip  saddr 10.11.0.0/16 meta iifname != "g*" meta oifname "en*" reject
                            ip6 saddr fd11::/16    meta iifname != "g*" meta oifname "en*" reject
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
        in {
            before = [ "network-pre.target" ];
            wants = [ "network-pre.target" ];
            wantedBy = [ "multi-user.target" ];
            restartIfChanged = true;
            postStop = "${pkgs.nftables}/bin/nft delete table inet firewall || true";
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = script;
            };
        };
    };
}