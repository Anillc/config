{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta) id name wg-public-key; peer = 16808; cost = 200;  }
        { inherit (hk.meta)   id name wg-public-key; peer = 11008; cost = 400;  }
    ];
    systemd.network = mkMerge [{
        networks.enp2s0 = {
            matchConfig.Name = "enp3s0";
            bridge = [ "br11" ];
        };
        networks.default-network = {
            matchConfig.Name = "enp1s0";
            DHCP = "ipv4";
        };
    } {
        # for masquerade
        networks = listToAttrs (map (x: nameValuePair "i${x.name}" {
            address = [ "${config.meta.v4}/32" "${config.meta.v6}/128" "${config.meta.externalV6}/128" ];
        }) config.wgi);
    }];
    bgp.enable = true;
    services.hostapd = {
        enable = false;
        radios.wlp2s0 = {
            channel = 8;
            countryCode = "CN";
            settings.bridge = "br11";
            networks.wlp2s0 = {
                ssid = "Anillc's AP";
                authentication = {
                    mode = "wpa2-sha256";
                    wpaPassword = "AnillcDayo";
                };
            };
        };
    };
    # systemd.timers.connect = {
    #     wantedBy = [ "timers.target" ];
    #     partOf = [ "connect.service" ];
    #     timerConfig = {
    #         OnCalendar = "*:0/20";
    #         Unit = "connect.service";
    #         Persistent = true;
    #     };
    # };
    # systemd.services.connect = {
    #     wantedBy = [ "multi-user.target" ];
    #     restartIfChanged = true;
    #     path = with pkgs; [ curl ];
    #     script = config.sops.secrets.school-network.path;
    #     serviceConfig = {
    #         Type = "oneshot";
    #         RemainAfterExit = true;
    #         Restart = "on-failure";
    #     };
    # };
}