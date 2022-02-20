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
        after = [ "network-online.target" "net.service" ];
        wantedBy = [ "multi-user.target" ];
    };
    firewall.extraNatRules = ''
        ip  saddr 192.168.233.0/24 meta iif br0 meta oif ishanghai snat to 172.22.167.107
        ip6 saddr fdff:233::/64    meta iif br0 meta oif ishanghai snat to fdc9:83c1:d0ce::11
        ip  saddr 192.168.233.0/24 meta iif br0 masquerade
        ip6 saddr fdff:233::/64    meta iif br0 masquerade
    '';
    networking.interfaces.enp1s0.useDHCP = true;
    net = {
        addresses = [
            { address = "192.168.233.1/24"; interface = "br0"; }
            { address = "fdff:233::1/64";   interface = "br0"; }
        ];
        routes = [
            { dst = "172.20.0.0/14"; src = "172.22.167.107";     interface = "ishanghai"; gateway = "172.22.167.105";    onlink = true; }
            { dst = "10.0.0.0/8";    src = "172.22.167.107";     interface = "ishanghai"; gateway = "172.22.167.105";    onlink = true; }
            { dst = "fd00::/8";      src = "fdc9:83c1:d0ce::11"; interface = "ishanghai"; gateway = "fdc9:83c1:d0ce::9"; onlink = true; }
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
        servers = [ "223.5.5.5" "172.20.0.53" ];
        extraConfig = ''
            interface=br0
            bogus-priv
            enable-ra
            dhcp-range=192.168.233.2,192.168.233.254,24h
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