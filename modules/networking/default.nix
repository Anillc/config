{ config, pkgs, lib, ... }: with lib; let
    # TODO: use another name
    cfg = config.bgp;
in {
    imports = [
        ./nftables.nix
        ./wg.nix
        ./wg-internal.nix
        ./babeld.nix
    ];
    systemd.network.enable = true;
    boot.kernel.sysctl = mkForce {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
    };
    systemd.network = {
        netdevs.dummy2526.netdevConfig = {
            Name = "dummy2526";
            Kind = "dummy";
        };
        networks.dummy2526 = {
            matchConfig.Name = "dummy2526";
            addresses = [
                { addressConfig = { Address = "2602:feda:da0::${cfg.meta.id}/128"; }; }
                { addressConfig = { Address = "${cfg.bgpSettings.dn42.v4}/32"; }; }
                { addressConfig = { Address = "${cfg.bgpSettings.dn42.v6}/128"; }; }
            ];
            routes = [
                { routeConfig = { Destination = "2602:feda:da0::${cfg.meta.id}/128"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "${cfg.bgpSettings.dn42.v4}/32"; Table = 114; Protocol = 114; }; }
                { routeConfig = { Destination = "${cfg.bgpSettings.dn42.v6}/128"; Table = 114; Protocol = 114; }; }
            ];
        };
        networks.table.routingPolicyRules = [{ routingPolicyRuleConfig.Table = 114; }];
    };
    systemd.services.table = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        script = ''
            ${pkgs.iproute2}/bin/ip -4 rule add table 114
            ${pkgs.iproute2}/bin/ip -6 rule add table 114
        '';
    };
}