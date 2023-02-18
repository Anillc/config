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
        { inherit (cola.meta) name wg-public-key; peer = 16808; cost = 200; }
        { inherit (hk.meta)   name wg-public-key; peer = 11008; cost = 400; }
    ];
    systemd.network = mkMerge [{
        networks.enp2s0 = {
            matchConfig.Name = "enp2s0";
            bridge = [ "br11" ];
        };
        networks.default-network = {
            matchConfig.Name = "enp1s0";
            DHCP = "ipv4";
        };
    } {
        # for masquerade
        networks = listToAttrs (map (x: nameValuePair "i${x.name}" {
            address = [ "${config.meta.v4}/32" "${config.meta.v6}/128" "${config.meta.externalV6}/128" ];
        }) config.wgi);
    }];
    services.cron = {
        enable = true;
        systemCronJobs = [ "*/20 * * * * root ${connect}" ];
    };
    systemd.services.connect-to-school = {
        enable = true;
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
}