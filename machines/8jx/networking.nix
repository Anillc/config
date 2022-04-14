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
    networking.nameservers = [ "223.5.5.5" ];
    systemd.network = mkMerge [{
        netdevs.br0.netdevConfig = {
            Name = "br0";
            Kind = "bridge";
        };
        networks.bre = {
            matchConfig.Name = "enp2s0";
            bridge = [ "br0" ];
        };
        networks.br0 = {
            matchConfig.Name = "br0";
            address = [ "192.168.233.1/24" "fdff:233::1/64" ];
        };
        networks.default-network = {
            matchConfig.Name = "enp1s0";
            DHCP = "ipv4";
        };
    } {
        # for masquerade
        networks = listToAttrs (map (x: nameValuePair "i${x.name}" {
            address = [ "${config.meta.v4}/32" "${config.meta.v6}/128" "2602:feda:da0::${toHexString config.meta.id}/128" ];
        }) config.wgi);
    }];

    services.cron = {
        enable = true;
        systemCronJobs = [ "*/20 * * * * root ${connect}" ];
    };
    systemd.services.connect-to-school = {
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
    firewall.extraPostroutingRules = ''
        ip  saddr 192.168.233.0/24 meta iifname br0 masquerade
        ip6 saddr fdff:233::/64    meta iifname br0 masquerade
    '';
    firewall.extraPreroutingRules = ''
        ip saddr 10.11.0.0/16 ip daddr 10.11.0.8 tcp dport 8005 dnat to 192.168.233.241
    '';

    networking.resolvconf.useLocalResolver = lib.mkForce false;
    firewall.publicTCPPorts = [ 53 ];
    firewall.publicUDPPorts = [ 53 ];
    # dhcp
    firewall.extraInputRules = "ip saddr 0.0.0.0/32 accept";
    services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        # servers = [ "172.22.167.125" ];
        servers = [ "223.5.5.5" ];
        extraConfig = ''
            interface=br0
            bogus-priv
            enable-ra
            dhcp-range=192.168.233.2,192.168.233.254,24h
            dhcp-range=fdff:233::2,fdff:233::fff,ra-only
        '';
    };
    systemd.services.hostapd = let
        # RTL8812BU
        conf1 = pkgs.writeText "hostapd.conf" ''
            interface=wlp0s29f7u4
            driver=nl80211
            ssid=Anillc's AP
            hw_mode=a
            channel=48
            ctrl_interface=/run/hostapd
            ctrl_interface_group=wheel
            wpa=2
            wpa_passphrase=AnillcDayo
            bridge=br0
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
            bridge=br0
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