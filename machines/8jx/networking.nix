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
    systemd.services.connect-to-school = {
        script = "${connect}";
        after = [ "network-online.target" "net-online.service" ];
        wantedBy = [ "multi-user.target" ];
    };
    firewall.extraPostroutingRules = ''
        ip  saddr 192.168.233.0/24 meta iifname br0 masquerade
        ip6 saddr fdff:233::/64    meta iifname br0 masquerade
    '';
    networking.interfaces.enp1s0.useDHCP = true;
    net = {
        addresses = [
            { address = "192.168.233.1/24"; interface = "br0"; }
            { address = "fdff:233::1/64";   interface = "br0"; }
        ];
        up = [ "enp1s0" "enp2s0" "wlp0s29f7u4" ];
        bridges.br0 = [ "enp2s0" "wlp0s29f7u4" ];
    };

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
    services.hostapd = {
        enable = true;
        ssid = "Anillc's AP";
        interface = "wlp0s29f7u4";
        wpaPassphrase = "AnillcDayo";
        #hwMode = "a";
        #channel = 48;
        hwMode = "g";
        channel = 1;
        countryCode = "CN";
        extraConfig = ''
            ieee80211n=1
            # ieee80211ac=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
    };
}