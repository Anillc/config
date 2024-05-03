{ config, pkgs, lib, inputs, ... }:

with lib;
with builtins;

{
    firewall.extraPostroutingFilterRules = ''
        meta iifname lgr meta oifname "en*" meta mark set 0x114
    '';
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.11.1.6/32 via "lgr";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    systemd.services."container@lgr".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    };
    containers.lgr = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.lgr = {};
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        config = {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.lgr.ipv4.addresses = [{ address = "10.11.1.6"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "lgr"; };
            virtualisation.oci-containers = {
                backend = "podman";
                containers.lgr = {
                    image = "ghcr.io/konatadev/lagrange.onebot:edge";
                    extraOptions = [ "--network=host" ];
                    volumes = [
                        "lgr:/app/data"
                    ];
                };
            };
        };
    };
}