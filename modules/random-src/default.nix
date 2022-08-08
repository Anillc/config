{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    cfg = config.random-src;
in {
    options.random-src = {
        enable = mkEnableOption "random-src";
        igp = mkOption {
            type = types.str;
            description = "igp address";
        };
        prefix = mkOption {
            type = types.str;
            description = "prefix";
        };
        length = mkOption {
            type = types.int;
            description = "prefix length";
        };
    };
    config = {
        bgp.extraBirdConfig = ''
            protocol static {
                route ${cfg.igp}/128 via ${cfg.igp}%rsrc onlink;
                ipv6 {
                    table igp_v6;
                };
            }
            protocol static {
                route ${cfg.prefix}/${toString cfg.length} via ${cfg.igp}%rsrc onlink;
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
                system.stateVersion = "22.05";
                documentation.enable = false;
                networking.firewall.enable = false;
                networking.interfaces.rsrc.ipv6.addresses = [{ address = cfg.igp; prefixLength = 128; }];
                networking.defaultGateway6 = { address = config.meta.v6; interface = "rsrc"; };
                networking.nftables = {
                    enable = true;
                    ruleset = ''
                        table inet rsrc {
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
                    path = [ inputs.random-src.packages.${pkgs.system}.random-src ];
                    script = "random-src ${cfg.igp} ${cfg.prefix} ${toString cfg.length}";
                };
            };
        };
    };
}