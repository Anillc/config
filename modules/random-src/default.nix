{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    cfg = config.random-src;
in {
    options.random-src = {
        enable = mkEnableOption "random-src";
        v4 = mkOption {
            type = types.str;
            description = "igp v4 address";
        };
        v6 = mkOption {
            type = types.str;
            description = "igp v6 address";
        };
        prefix = mkOption {
            type = types.str;
            description = "prefix";
        };
        length = mkOption {
            type = types.int;
            description = "prefix length";
        };
        config = mkOption {
            type = types.anything;
            description = "config";
        };
    };
    config = mkIf cfg.enable {
        bgp.extraBirdConfig = ''
            protocol static {
                route ${cfg.v4}/32 via "rsrc";
                ipv4 {
                    table igp_v4;
                };
            }
            protocol static {
                route ${cfg.v6}/128 via ${cfg.v6}%rsrc onlink;
                ipv6 {
                    table igp_v6;
                };
            }
            protocol static {
                route ${cfg.prefix}/${toString cfg.length} via ${cfg.v6}%rsrc onlink;
                ipv6 {
                    table igp_v6;
                };
            }
        '';
        systemd.network.networks.random-src = {
            matchConfig.Name = "rsrc";
            address = [ "${config.meta.v6}/128" ];
        };
        containers.random-src = {
            autoStart = true;
            privateNetwork = true;
            extraVeths.rsrc = {};
            config = {
                imports = [ cfg.config ];
                system.stateVersion = "22.05";
                documentation.enable = false;
                networking.firewall.enable = false;
                networking.interfaces.rsrc.ipv4.addresses = [{ address = cfg.v4; prefixLength = 32; }];
                networking.interfaces.rsrc.ipv6.addresses = [{ address = cfg.v6; prefixLength = 128;  }];
                networking.defaultGateway  = { address = config.meta.v4; interface = "rsrc"; };
                networking.defaultGateway6 = { address = config.meta.v6; interface = "rsrc"; };
                networking.nftables = {
                    enable = true;
                    ruleset = ''
                        table ip6 rsrc {
                            chain prerouting {
                                type filter hook prerouting priority 0;
                                queue num 114
                            }
                            chain output {
                                type filter hook output priority 0;
                                queue num 514
                            }
                        }
                    '';
                };
                systemd.services.random-src = {
                    wantedBy = [ "multi-user.target" ];
                    after = [ "network-online.target" ];
                    serviceConfig.Restart = "always";
                    path = [ inputs.random-src.packages.${pkgs.system}.random-src ];
                    script = "random-src ${cfg.v6} ${cfg.prefix} ${toString cfg.length}";
                };
            };
        };
    };
}