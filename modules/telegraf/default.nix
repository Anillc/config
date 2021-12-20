{ pkgs, ...}: {
    services.telegraf = {
        enable = true;
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
            };
            outputs.influxdb_v2 = {
                urls = ["http://172.22.167.105:8086"];
                token = "d2r575_TnHszNBVnApmX9-wwSFvpf0CQlCT85x8XGSa8hAMia6sjm4DCDwFhY42_oJR0_ie-ju1CYn8iYHI0HQ==";
                organization = "AnillcNetwork";
                bucket = "servers";
            };
        };
    };
}