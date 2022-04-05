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
        { inherit (sh.meta) name wg-public-key; peer = 11008; }
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
            address = [ "${config.meta.v4}/32" "${config.meta.v6}/128" ];
        }) config.wgi);
    }];

    services.cron = {
        enable = true;
        systemCronJobs = [ "*/20 * * * * root ${connect}" ];
    };
    systemd.services.connect-to-school = {
        script = "${connect}";
        after = [ "network-online.target" "systemd-networkd.service" ];
        wantedBy = [ "multi-user.target" ];
    };
    firewall.extraPostroutingRules = ''
        ip  saddr 192.168.233.0/24 meta iifname br0 masquerade
        ip6 saddr fdff:233::/64    meta iifname br0 masquerade
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
    services.hostapd = {
        enable = true;
        ssid = "Anillc's AP";
        interface = "wlp0s29f7u4";
        wpaPassphrase = "AnillcDayo";
        hwMode = "a";
        channel = 48;
        # hwMode = "g";
        # channel = 11;
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
}