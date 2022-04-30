{ config, pkgs, lib, ... }: {
    firewall.extraPostroutingFilterRules = "meta iifname nnhr meta oifname ens18 meta mark set 0x114";
    systemd.network.networks.nanahira = {
        matchConfig.Name = "nnhr";
        address = [ "192.168.114.1/24" ];
    };
    bgp.extraBirdConfig = ''
        protocol static {
            route 10.198.0.0/16 via 192.168.114.2;
            ipv4 {
                table igp_v4;
            };
        }
        protocol static {
            route 192.168.123.0/24 via 192.168.114.2;
            ipv4 {
                table igp_v4;
            };
        }
    '';
    # use 192.168.114.1/24 and 192.168.114.2/24
    containers.nanahira = {
        autoStart = true;
        privateNetwork = true;
        extraVeths.nnhr = {};
        bindMounts."/run/secrets".isReadOnly = true;
        config = { pkgs, ... }: {
            documentation.enable = false;
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
                        endpoint = "yangtze-v4.mycard.moe:28010";
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
            systemd.services.setup-network = {
                wantedBy = [ "multi-user.target" ];
                requires = [ "wireguard-nanahira.service" "network-online.target" ];
                after = [ "wireguard-nanahira.service" "network-online.target" ];
                script = ''
                    ${pkgs.iproute2}/bin/ip address add 192.168.114.2/24 dev nnhr
                    ${pkgs.iproute2}/bin/ip route add default via 192.168.114.1
                    ${pkgs.iproute2}/bin/ip route add 10.11.0.0/16 via 192.168.114.1 proto 114
                '';
            };
        };
    };
}