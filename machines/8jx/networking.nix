{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    connect = pkgs.writeScript "connect" ''
        export PATH=$PATH:${with pkgs; makeBinPath [
            curl
        ]}
        ${config.sops.secrets.school-network.path}
    '';
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta) name wg-public-key; peer = 11008; cost = 200; }
        { inherit (wh.meta) name wg-public-key; peer = 21122; cost = 160; }
    ];
    systemd.network = mkMerge [{
        networks.enp2s0 = {
            matchConfig.Name = "enp2s0";
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

    services.cron = {
        enable = true;
        # systemCronJobs = [ "*/20 * * * * root ${connect}" ];
    };
    systemd.services.connect-to-school = {
        enable = false;
        after = [ "network-online.target" "systemd-networkd.service" ];
        partOf = [ "systemd-networkd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
        };
        script = "${connect}";
    };
    systemd.services.hostapd = let
        # RTL8812BU
        conf1 = pkgs.writeText "hostapd.conf" ''
            interface=wlp0s29f7u4
            driver=nl80211
            ssid=Anillc's AP
            hw_mode=a
            channel=165
            ctrl_interface=/run/hostapd
            ctrl_interface_group=wheel
            wpa=2
            wpa_passphrase=AnillcDayo
            bridge=br11
            ieee80211n=1
            ieee80211ac=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
        conf2 = pkgs.writeText "hostapd.conf" ''
            interface=wlp0s29f7u2
            driver=nl80211
            ssid=Anillc's AP
            hw_mode=g
            channel=11
            ctrl_interface=/run/hostapd
            ctrl_interface_group=wheel
            wpa=2
            wpa_passphrase=AnillcDayo
            bridge=br11
            ieee80211n=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
    in {
        after = [ "systemd-networkd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            ExecStart = "${pkgs.hostapd}/bin/hostapd ${conf1} ${conf2}";
            Restart = "always";
        };
    };
}