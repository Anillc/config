{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    cfg.wgi = with machines.set; [
        { inherit (cola.meta) id name wg-public-key; peer = 16808; cost = 200;  }
        { inherit (sum.meta)  id name wg-public-key; peer = 11008; cost = 570;  }
        { inherit (lux.meta)  id name wg-public-key; peer = 11008; cost = 3000; }
    ];
    systemd.network.networks.default-network = {
        matchConfig.Name = "enp1s0";
        DHCP = "ipv4";
    };
    cfg.access = {
        enable = true;
        interface = "enp3s0";
        ip = "10.11.1.4";
    };
    # services.hostapd = {
    #     enable = false;
    #     radios.wlp2s0 = {
    #         channel = 8;
    #         countryCode = "CN";
    #         settings.bridge = "br11";
    #         networks.wlp2s0 = {
    #             ssid = "Anillc's AP";
    #             authentication = {
    #                 mode = "wpa2-sha256";
    #                 wpaPassword = "AnillcDayo";
    #             };
    #         };
    #     };
    # };
}