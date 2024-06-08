{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; peer = 11002; cost = 1900; }
        { inherit (fmt.meta) name wg-public-key; peer = 11002; cost = 1300; }
    ];
    bgp = {
        enable = true;
        peers.kskbix = {
            asn = "199594";
            address = "fe80::1980:1:1%eth1";
            extraConfig = ''
                source address fe80::142:55;
            '';
        };
    };
    dns.enable = false;
    networking.nameservers = lib.mkForce [ "127.0.0.1" ];
    services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings.server = [
            "/a/10.11.1.2"

            "114.114.114.114"
            "223.5.5.5"
            "8.8.8.8"
            "8.8.4.4"
        ];
    };
}