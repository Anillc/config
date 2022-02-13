{ config, pkgs, lib, ... }: let
    connect = pkgs.writeScript "connect" ''
        export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
            curl
        ]}
        ${config.sops.secrets.school-network.path}
    '';
in {
    services.cron = {
        enable = true;
        systemCronJobs = [ "*/20 * * * * root ${connect}" ];
    };
    systemd.services.connectToSchool = {
        script = "${connect}";
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
    };
    firewall.extraNatRules = "ip saddr 10.127.20.128/25 meta iif br0 meta oif enp1s0 masquerade";
    systemd.network = {
        netdevs.enp2s0.netdevConfig = {
            Name = "br0";
            Kind = "bridge";
        };
        networks = {
            enp1s0 = {
                matchConfig.Name = "enp1s0";
                DHCP = "ipv4";
            };
            enp2s0 = {
                matchConfig.Name = "enp2s0";
                bridge = [ "br0" ];
            };
            wlp0s29f7u4 = {
                matchConfig.Name = "wlp0s29f7u4";
                bridge = [ "br0" ];
            };
            br0 = {
                matchConfig.Name = "br0";
                addresses = [
                    { addressConfig.Address = "10.127.20.129/25"; }
                    { addressConfig.Address = "2602:feda:da1::1/96"; }
                ];
            };
        };
    };
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    firewall.publicTCPPorts = [ 53 ];
    firewall.publicUDPPorts = [ 53 ];
    services.dnsmasq = {
        enable = true;
        servers = [ "223.5.5.5" "172.20.0.53" ];
        extraConfig = ''
            interface=br0
            bogus-priv
            enable-ra
            dhcp-range=10.127.20.130,10.127.20.254,24h
        '';
    };
    services.hostapd = {
        enable = true;
        ssid = "Anillc's AP";
        interface = "wlp0s29f7u4";
        wpaPassphrase = "AnillcDayo";
        hwMode = "a";
        channel = 48;
        #hwMode = "g";
        #channel = 6;
        countryCode = "CN";
        extraConfig = ''
            ieee80211n=1
            ieee80211ac=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
    };
    networking.nameservers = lib.mkForce [ "223.5.5.5" ];
}