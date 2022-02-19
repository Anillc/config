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
    firewall.extraNatRules = ''
        ip  saddr 192.168.233.0/24 meta iif br0 meta oif ishanghai snat ip to 172.22.167.107
        ip6 saddr fdff:233::/64 meta iif br0 meta oif ishanghai snat ip6 to fdc9:83c1:d0ce::11
        ip  saddr 192.168.233.0/24 meta iif br0 masquerade
        ip6 saddr fdff:233::/64    meta iif br0 masquerade
    '';
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
            # bridge wlp0s29f7u4 in hostapd
            br0 = {
                matchConfig.Name = "br0";
                addresses = [
                    { addressConfig.Address = "192.168.233.1/24"; }
                    { addressConfig.Address = "fdff:233::1/64"; }
                ];
            };
            ishanghai = {
                routes = [
                    { routeConfig = { Gateway = "172.22.167.105"; Destination = "172.16.0.0/12"; PreferredSource = "172.22.167.107"; GatewayOnLink = "yes"; }; }
                    { routeConfig = { Gateway = "172.22.167.105"; Destination = "10.0.0.0/8"; PreferredSource = "172.22.167.107"; GatewayOnLink = "yes"; }; }
                    { routeConfig = { Gateway = "fdc9:83c1:d0ce::9"; Destination = "fd00::/8"; PreferredSource = "fdc9:83c1:d0ce::11"; GatewayOnLink = "yes"; }; }
                ];
            };
        };
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
            bridge=br0
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