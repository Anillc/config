{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
    cfg = config.rsrc;
    psocket-run = inputs.psocket-run.packages.${pkgs.system}.default;
    host-addr = "fe80::508e:ebd2:e461:15bf";
    container-addr = "fe80::508e:ebd2:e461:15be";
in {
    options.rsrc = {
        enable = mkEnableOption "rsrc";
        cidr = mkOption {
            type = types.str;
            description = "cidr";
        };
        proxy = mkOption {
            type = types.str;
            description = "proxy";
        };
        proxyHost = mkOption {
            type = types.str;
            description = "proxy host";
        };
        port = mkOption {
            type = types.int;
            description = "port";
            default = 8080;
        };
        webPort = mkOption {
            type = types.int;
            description = "web port";
            default = 8081;
        };
    };
    config = mkIf cfg.enable {
        bgp.extraBirdConfig = ''
            protocol static {
                route ${cfg.cidr} via "lo";
                ipv6 {
                    table igp_v6;
                };
            }
        '';
        boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = 1;
        systemd.services.rsrc = {
            wantedBy = [ "multi-user.target" ];
            after = [ "nginx.service" "network-online.target" ];
            path = with pkgs; [ iproute2 psocket-run mitmproxy];
            serviceConfig = {
                User = "root";
                Group = "root";
                ExecStart = "+${pkgs.writeScript "rsrc-start" ''
                    #!${pkgs.runtimeShell}
                    ip route replace local ${cfg.cidr} dev lo
                    psocket-run -c ${cfg.cidr} "mitmweb \
                        -m reverse:${cfg.proxy} -H '/~q/Host/${cfg.proxyHost}' -k \
                        -p ${toString cfg.port} --web-host 0.0.0.0 --web-port ${toString cfg.webPort}"
                ''}";
                ExecStop = pkgs.writeScript "rsrc-stop" ''
                    #!${pkgs.runtimeShell}
                    ip route del local ${cfg.cidr} || true
                '';
            };
        };
    };
}