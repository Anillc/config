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
    containers.chronocat = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.chronocat = {};
        config = {
            system.stateVersion = "22.05";
            networking.firewall.enable = false;
            networking.interfaces.chronocat.ipv4.addresses = [{ address = "10.11.1.6"; prefixLength = 32;  }];
            networking.defaultGateway  = { address = config.meta.v4; interface = "chronocat"; };
            systemd.services.xvfb = {
                wantedBy = [ "multi-user.target" ];
                path = with pkgs; [ xorg.xorgserver ];
                script = "Xvfb :11";
            };
            systemd.services.vnc = {
                wantedBy = [ "multi-user.target" ];
                after = [ "xvfb.service" ];
                path = with pkgs; [ x11vnc ];
                script = "x11vnc -forever -display :11";
            };
            systemd.services.chronocat = {
                wantedBy = [ "multi-user.target" ];
                after = [ "xvfb.service" "vnc.service" ];
                path = with pkgs; [ util-linux inputs.chronocat.packages.${pkgs.system}.default ];
                script = ''
                    mkdir -p /var/lib/chronocat /build/home
                    cd /var/lib/chronocat
                    export DISPLAY=:11
                    sleep 3
                    script -q <<EOF
                        chronocat
                        while :; do
                            sleep 114514
                        done
                    EOF
                '';
            };
        };
    };
}