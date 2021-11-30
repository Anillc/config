{ pkgs, config, lib, ... }: with lib; let
    cfg = config.bgp;
    roa = pkgs.writeScript "roa" ''
        mkdir -p /var/bird
        ${pkgs.wget}/bin/wget -4 -O /var/bird/roa_dn42_v6.conf https://dn42.burble.com/roa/dn42_roa_bird2_6.conf
        ${pkgs.wget}/bin/wget -4 -O /var/bird/roa_dn42.conf https://dn42.burble.com/roa/dn42_roa_bird2_4.conf
    '';
    ptp = pkgs.writeScript "ptp" ''
        mkdir -p /var/bird
        ${ptpScript} | tee /var/bird/ptp.conf
    '';
    ptpScript = pkgs.writeScript "ptp" ''
        export PATH=$PATH:${with pkgs; lib.strings.makeBinPath [
            iputils
            gawk
        ]}

        # modified from https://gist.github.com/moesoha/8a97483fff45003c33ddd2e42a7c4d44

        # gathering all interfaces with IPv6 link-local address
        for with_ll in $(cat /proc/net/if_inet6 | grep "^fe80" | tr -s ' ' | cut -d ' ' -f 6 | sort | uniq); do
            ptp() {
                # POINTOPOINT flag is 1 << 4, filter non-PTP interfaces out
                if [ $(expr \( $(($(cat /sys/class/net/$with_ll/flags))) / 16 \) % 2) -ne 1 ]; then
                    return
                fi
                cost=65535
                ping_rtt=N/A
                ping_result=$(ping -6 -q -L -n -i 1 -c 10 -W 10 ff02::1%$with_ll)
                ping_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
                if [ $ping_loss -ne 100 ]; then
                    ping_rtt=$(echo "$ping_result" | tail -1 | cut -d ' ' -f 4 | cut -d '/' -f 2)
                    cost=$(echo | awk '{ printf "%0.0f\n", ('$ping_rtt' * 100 / (100 - '$ping_loss') * 10); }')
                fi
                echo 'define ptp_'$with_ll' = '$cost'; # loss '$ping_loss'%, rtt '$ping_rtt'ms'
            }
            ptp &
        done

        sleep 21
    '';
in {
    config = mkIf cfg.enable {
        services.cron.systemCronJobs = [
            "*/15 * * * * root ${roa} && ${ptp} && ${pkgs.bird2}/bin/birdc c"
        ];
        services.bird2 = {
            enable = true;
            checkConfig = false;
            config = ''
                ${import ./config.nix pkgs cfg}
                ${cfg.extraBirdConfig}
            '';
        };
        systemd.services.bird2 = {
            reloadIfChanged = mkForce false;
            preStart = "${roa} && ${ptp}";
            after = [ "network-online.target" ];
        };
    };
}