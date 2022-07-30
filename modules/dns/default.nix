{ config, lib, ... }:

with builtins;
with lib;

{
    options.dns.enable = mkOption {
        type = types.bool;
        description = "dns";
        default = true;
    };
    imports = [
        ./knot.nix
        ./dnsmasq.nix
    ];
    config = {
        networking.nameservers = [ "10.11.1.2" ];
    };
}