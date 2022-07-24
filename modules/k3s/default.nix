{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    address = "10.11.3.${toString config.meta.id}";
in {
    bgp.extraBirdConfig = ''
        protocol static {
            route ${address}/32 via "k3s";
            ipv4 {
                table igp_v4;
            };
        }
    '';
    firewall.extraPostroutingFilterRules = ''
        meta iifname k3s meta oifname "en*" meta mark set 0x114
    '';
    sops.secrets.k3s-token.sopsFile = ./secrets.yaml;
    systemd.services."container@k3s".environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
        SYSTEMD_NSPAWN_API_VFS_WRITABLE = "1";
    };
    containers.k3s = {
        autoStart = true;
        privateNetwork = true;
        extraFlags = [
            "--system-call-filter=add_key"
            "--system-call-filter=keyctl"
            "--system-call-filter=bpf"
        ];
        extraVeths.k3s = {};
        bindMounts."/run/secrets" = {};
        config = {
            # TODO: config.system.stateVersion
            system.stateVersion = "22.05";
            documentation.enable = false;
            networking.hostName = "${config.meta.name}-k3s";
            networking.firewall.enable = false;
            networking.interfaces.k3s.ipv4.addresses = [{ inherit address; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "k3s"; };
            services.k3s = mkMerge [
                { enable = true; }
                (mkIf (config.meta.name == "sh") {
                    role = "server";
                    extraFlags = "--disable traefik";
                })
                (mkIf (config.meta.name != "sh") {
                    role = "agent";
                    serverAddr = "https://10.11.3.1:6443";
                    tokenFile = config.sops.secrets.k3s-token.path;
                })
            ];
        };
    };
}