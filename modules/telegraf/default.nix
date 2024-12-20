{ config, pkgs, ...}: {
    sops.secrets.telegraf-env = {
        sopsFile = ./secrets.yaml;
        owner = "telegraf";
        group = "telegraf";
    };
    services.telegraf = {
        enable = true;
        environmentFiles = [ config.sops.secrets.telegraf-env.path ];
        extraConfig = {
            inputs = {
                cpu = {
                    percpu = true;
                    totalcpu = true;
                    collect_cpu_time = false;
                    report_active = false;
                };
                mem = {};
                disk.ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" ];
                diskio = {};
                net = {};
                system = {};
                systemd_units = {};
            };
            outputs.influxdb_v2 = {
                urls = ["http://cola.a:8086"];
                token = "$TOKEN";
                organization = "AnillcNetwork";
                bucket = "servers";
            };
        };
    };
}