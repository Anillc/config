{ config, pkgs, ... }: {
    firewall.extraNatRules = "meta iif ve-nanahira meta oif ens18 masquerade";
    systemd.services.nftables.requires = [ "container@nanahira.service" ];
    # systemd.network.networks.nanahira-network = {
    #     matchConfig.Name = "ve-nanahira";
    #     routes = [
    #         { routeConfig = { Gateway = "192.168.114.2"; Source = "172.22.167.106/32"; Destination = "10.198.0.0/16"; Table = 114; Protocol = 114; }; }
    #         { routeConfig = { Gateway = "192.168.114.2"; Source = "172.22.167.106/32"; Destination = "192.168.123.0/24"; Table = 114; Protocol = 114; }; }
    #     ];
    # };
    # systemd.services.nanahira-network = {
    #     wantedBy = [ "multi-user.target" ];
    #     partOf = [ "dummy.service" ];
    #     requires = [ "container@nanahira.service" "network-online.target" ];
    #     after = [ "container@nanahira.service" "network-online.target" ];
    #     script = ''
    #         ${pkgs.iproute2}/bin/ip route del 10.198.0.0/16    table 114 || true
    #         ${pkgs.iproute2}/bin/ip route del 192.168.123.0/24 table 114 || true
    #         ${pkgs.iproute2}/bin/ip route add 10.198.0.0/16    src 172.22.167.106 via 192.168.114.2 proto 114 table 114
    #         ${pkgs.iproute2}/bin/ip route add 192.168.123.0/24 src 172.22.167.106 via 192.168.114.2 proto 114 table 114
    #     '';
    # };
    containers.nanahira = {
        autoStart = true;
        privateNetwork = true;
        hostAddress  = "192.168.114.1";
        localAddress = "192.168.114.2";
        bindMounts."/run/secrets".isReadOnly = true;
        config = { pkgs, ... }: {
            environment.systemPackages = with pkgs; [ tcpdump iptables ];
            boot.kernel.sysctl = pkgs.lib.mkForce {
                "net.ipv4.ip_forward" = 1;
                "net.ipv6.conf.all.forwarding" = 1;
                "net.ipv4.conf.all.rp_filter" = 0;
            };
            networking.firewall.enable = false;
            networking.wireguard = {
                interfaces.nanahira = {
                    privateKeyFile = config.sops.secrets.wg-nanahira-private-key.path;
                    allowedIPsAsRoutes = false;
                    postSetup = ''
                        ${pkgs.iproute2}/bin/ip link set nanahira mtu 1362
                        ${pkgs.iproute2}/bin/ip route add 10.200.1.10/32 dev nanahira
                    '';
                    ips = [ "10.200.10.1/32" "fe80::1:a01/64"];
                    peers = [{
                        publicKey = "cmcLT53EJSji4cWsvziFvSmX+elN05S0P9AQSCjpEQM=";
                        persistentKeepalive = 25;
                        # yangtze-v4.mycard.moe
                        endpoint = "58.32.12.110:28010";
                        allowedIPs = [ "0.0.0.0/0" "::/0" ];
                    }];
                };
            };
            services.babeld = {
                enable = true;
                interfaces.nanahira = {
                    type = "tunnel";
                    link-quality = true;
                    max-rtt-penalty = 1024;
                    rtt-max = 1024;
                    split-horizon = false;
                    hello-interval = 20;
                    rxcost = 32;
                };
                extraConfig = ''
                    redistribute proto 114 allow
                    redistribute local deny
                '';
            };
            systemd.services.redistribute-network = {
                wantedBy = [ "multi-user.target" ];
                requires = [ "wireguard-nanahira.service" "network-online.target" ];
                after = [ "wireguard-nanahira.service" "network-online.target" ];
                script = ''
                    ${pkgs.iproute2}/bin/ip route del 172.22.167.96/27 || true
                    ${pkgs.iproute2}/bin/ip route del 10.127.20.0/24   || true
                    ${pkgs.iproute2}/bin/ip route add 172.22.167.96/27 via 192.168.114.1 proto 114
                    ${pkgs.iproute2}/bin/ip route add 10.127.20.0/24   via 192.168.114.1 proto 114
                '';
            };
        };
    };
}