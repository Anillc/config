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
    networking.nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
        externalInterface = "enp1s0";
        internalIPs = [ "10.127.20.128/25" ];
    };
    networking.bridges = {
        "br0".interfaces = [ "enp2s0" "wlp0s29f7u4" ];
    };
    networking.interfaces.br0.ipv4.addresses = [{
        address = "10.127.20.129";
        prefixLength = 25;
    }];
    networking.interfaces.br0.ipv6.addresses = [{
        address = "2602:feda:da1:1::1";
        prefixLength = 96;
    }];
    networking.interfaces.enp2s0.useDHCP = false;
    networking.interfaces.wlp0s29f7u4.useDHCP = false;
    # have been defined in bgp module
    # boot.kernel.sysctl = {
    #     "net.ipv4.ip_forward" = 1;
    #     "net.ipv6.conf.all.forwarding" = 1;
    # };
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
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
        #hwMode = "a";
        #channel = 48;
        hwMode = "g";
        channel = 6;
        countryCode = "CN";
        extraConfig = ''
            ieee80211n=1
            #ieee80211ac=1
            wmm_enabled=1
            auth_algs=1
            wpa_key_mgmt=WPA-PSK
            rsn_pairwise=CCMP
        '';
    };
    networking.nameservers = lib.mkForce [ "223.5.5.5" ];
}