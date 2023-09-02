{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (cola.meta) name wg-public-key; peer = 16808; cost = 200;  }
        { inherit (hk.meta)   name wg-public-key; peer = 11008; cost = 400;  }
        { inherit (hk2.meta)  name wg-public-key; peer = 11008; cost = 3640; }
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
    services.hostapd = {
        enable = true;
        interface = "wlp2s0";
        ssid = "Anillc's AP";
        wpaPassphrase = "AnillcDayo";
        channel = 8;
        extraConfig = ''
            bridge=br11
            wpa=2
            ieee80211n=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
    };
    systemd.timers.connect = {
        wantedBy = [ "timers.target" ];
        partOf = [ "connect.service" ];
        timerConfig = {
            OnCalendar = "*:0/20";
            Unit = "connect.service";
            Persistent = true;
        };
    };
    systemd.services.connect = {
        wantedBy = [ "multi-user.target" ];
        restartIfChanged = true;
        path = with pkgs; [ curl ];
        script = config.sops.secrets.school-network.path;
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
        };
    };
}