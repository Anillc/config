{ config, lib, ... }:

with builtins;
with lib;

let
    cfg = config.meta;
in {
    options.meta = {
        enable = mkOption {
            type = types.bool;
            description = "enable deploy";
            default = true;
        };
        id = mkOption {
            type = types.int;
            description = "id";
        };
        name = mkOption {
            type = types.str;
            description = "name";
        };
        address = mkOption {
            type = types.str;
            description = "address";
            default = cfg.v4;
        };
        system = mkOption {
            type = types.str;
            description = "system";
            default = "x86_64-linux";
        };
        wg-public-key = mkOption {
            type = types.str;
            description = "wireguard public key";
        };
        v4 = mkOption {
            type = types.str;
            description = "ipv4 address (internel)";
            default = "10.11.0.${toString cfg.id}";
        };
        v6 = mkOption {
            type = types.str;
            description = "ipv6 address (internel)";
            default = "fd11::${toHexString cfg.id}";
        };
    };
}