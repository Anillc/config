{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    inherit (inputs.anillc.packages.${pkgs.system}) http-proxy-ipv6-pool;
    cfg = config.rsrc;
    cidr = "2a0e:b107:1172::/56";
in {
    options.rsrc.enable = mkEnableOption "rsrc";
    config = mkIf cfg.enable {
        systemd.network.networks.rsrc = {
            matchConfig.Name = "rsrc";
            address = [ "fe80::114:514/64" ];
        };
        bgp.extraBirdConfig = ''
            protocol static {
                route 10.11.1.5/32 via "rsrc";
                ipv4 {
                    table igp_v4;
                };
            }
            protocol static {
                route ${cidr} via fe80::1919:810%rsrc;
                ipv6 {
                    table igp_v6;
                };
            }
        '';
        containers.rsrc = {
            autoStart = true;
            privateNetwork = true;
            extraVeths.rsrc = {};
            config = {
                system.stateVersion = "22.05";
                boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = 1;
                networking.firewall.enable = false;
                networking.interfaces.rsrc.ipv4.addresses = [{ address = "10.11.1.5"; prefixLength = 32;  }];
                networking.interfaces.rsrc.ipv6.addresses = [{ address = "fe80::1919:810"; prefixLength = 64; }];
                networking.defaultGateway  = { address = config.meta.v4; interface = "rsrc"; };
                networking.defaultGateway6 = { address = "fe80::114:514"; interface = "rsrc"; };
                systemd.services.rsrc = {
                    wantedBy = [ "multi-user.target" "network-online.target" ];
                    path = with pkgs; [ iproute2 http-proxy-ipv6-pool ];
                    script = ''
                        ip route add local ${cidr} dev rsrc
                        http-proxy-ipv6-pool -b 0.0.0.0:1080 -i ${cidr}
                    '';
                };
            };
        };
    };
}