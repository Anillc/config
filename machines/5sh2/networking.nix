{ config, pkgs, lib, ... }: 

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta) name wg-public-key; peer = 11005; cost = 80; }
    ];
    networking.nameservers = [ "223.5.5.5" ];
    firewall.enableSourceFilter = false;
    systemd.network.networks.default-network = {
        matchConfig.Name = "ens18";
        address = [ "192.168.1.110/24" "fe80::115/64" ];
        gateway = [ "192.168.1.1" ];
    };
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.50.0.0/16 via 192.168.1.11;
            ipv4 {
                table igp_v4;
            };
        }
        protocol static {
            route fddd:5050::/64 via fe80::c274:2bff:feff:a618%ens18;
            ipv6 {
                table igp_v6;
            };
        }
    '';
}