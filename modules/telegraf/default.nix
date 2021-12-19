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
            };
            outputs.influxdb_v2 = {
                urls = ["http://172.22.167.97:8086"];
                token = "nn_M03qlDIfI_2zkyv5Cf3rXCuLfLKqKR8UK0jx3999MT4OjBIIVTfuv26cDiWx1X3wcYVWodg7U89mP2yBm_Q==";
                organization = "AnillcNetwork";
                bucket = "servers";
            };
        };
    };
}