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
            };
            outputs.influxdb_v2 = {
                urls = ["http://10.11.0.1:8086"];
                token = "$TOKEN";
                organization = "AnillcNetwork";
                bucket = "servers";
            };
        };
    };
}