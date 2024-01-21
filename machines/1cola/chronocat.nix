{ config, pkgs, lib, inputs, ... }:

with lib;
with builtins;

{
    firewall.extraPostroutingFilterRules = ''
        meta iifname chronocat meta oifname "en*" meta mark set 0x114
    '';
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.11.1.6/32 via "chronocat";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    systemd.services."container@chronocat".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    };
    containers.chronocat = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.chronocat = {};
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        config = {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.chronocat.ipv4.addresses = [{ address = "10.11.1.6"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "chronocat"; };
            virtualisation.oci-containers = {
                backend = "podman";
                containers.chronocat = {
                    image = "he0119/chronocat-docker";
                    extraOptions = [ "--network=host" "--tty" ];
                    environment.VNC_PASSWD = "qwq";
                    volumes = [
                        "tencent-files:/root/Tencent Files"
                        "chronocat-config:/wine/drive_c/users/root/.chronocat/config"
                        "ll:/root/LiteLoaderQQNT/plugins"
                    ];
                };
            };
        };
    };
}