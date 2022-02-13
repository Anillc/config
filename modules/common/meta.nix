{ pkgs, lib, ... }: with lib; {
    options.meta = {
        enable = mkOption {
            type = types.bool;
            description = "enable deploy";
            default = true;
        };
        id = mkOption {
            type = types.str;
            description = "id";
        };
        name = mkOption {
            type = types.str;
            description = "name";
        };
        address = mkOption {
            type = types.str;
            description = "address";
        };
        inNat = mkOption {
            type = types.bool;
            description = "in nat";
            default = false;
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
        connect = mkOption {
            type = types.listOf types.anything;
            description = "machines to be connected with";
        };
    };
}