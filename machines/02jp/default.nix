rec {
    meta = {
        id = "02";
        name = "jp";
        address = "jp.an.dn42";
        inNat = false;
        system = "x86_64-linux";
        wg-private-key = config: config.sops.secrets.wg-jp-private-key.path;
        wg-public-key = "HcvaoEtLGxv1tETLCjmcKXkr1CNwiF/ZsmIi7lYAvQ4=";
    };
    configuration = { config, pkgs, ... }: {
        imports = [
            ./hardware.nix
            (import ./bgp.nix meta)
        ];
        sops.secrets.wg-jp-private-key.sopsFile = ./secrets.yaml;
        sops.secrets.bot-env = {
            format = "binary";
            sopsFile = ./bot.env;
        };
        networking.hostName = meta.name;
        networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

        services.mysql = {
            enable = true;
            package = pkgs.mariadb;
            initialDatabases = [{
                name = "bot";
            }];
        };
        virtualisation.oci-containers = {
            backend = "podman";
            containers.bot = {
                image = "docker.io/anillc/cllina:eb23449";
                volumes = [
                    "/run/mysqld/mysqld.sock:/run/mysqld/mysqld.sock"
                    "${config.sops.secrets.bot-env.path}:/root/cllina/.env"
                    "/var/koishi:/root/cllina/.koishi"
                ];
                extraOptions = [ "--network=host" ];
            };
        };
        
        # bot telegram
        networking.firewall.extraCommands = ''
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8056 -s 172.22.167.96/27 -j nixos-fw-accept
            ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 8056 -s 10.127.20.0/24 -j nixos-fw-accept
        '';
        networking.firewall.extraStopCommands = ''
            ${pkgs.iptables}/bin/iptables -D nixos-fw -p tcp --dport 8056 -s 172.22.167.96/27 -j nixos-fw-accept || true
            ${pkgs.iptables}/bin/iptables -D nixos-fw -p tcp --dport 8056 -s 10.127.20.0/24 -j nixos-fw-accept   || true
        '';
    };
}