{ pkgs, config, lib, ... }: with lib; let
    cfg = config.bgp;
    roa = pkgs.writeScript "roa" ''
        mkdir -p /var/bird
        ${pkgs.wget}/bin/wget -4 -O /var/bird/roa_dn42_v6.conf https://dn42.burble.com/roa/dn42_roa_bird2_6.conf
        ${pkgs.wget}/bin/wget -4 -O /var/bird/roa_dn42.conf https://dn42.burble.com/roa/dn42_roa_bird2_4.conf
    '';
in {
    config = mkIf cfg.enable {
        sops.secrets.bird-conf = {
            sopsFile = ./secrets.yaml;
            owner = "bird2";
            group = "bird2";
            mode = "0600";
        };
        services.cron.systemCronJobs = [
            "*/15 * * * * root ${roa} && ${pkgs.bird2}/bin/birdc c"
        ];
        networking.firewall.allowedTCPPorts = [ 179 ];
        services.bird2 = {
            enable = true;
            checkConfig = false;
            config = ''
                ${import ./config.nix pkgs config}
                ${cfg.extraBirdConfig}
            '';
        };
        systemd.services.bird2 = {
            preStart = "${roa}";
            after = [ "network-online.target" ];
        };
    };
}