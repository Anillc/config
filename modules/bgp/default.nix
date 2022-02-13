{ config, pkgs, lib, ... }: with lib; let
    cfg = config.bgp;
in {
    imports = [
        ./bird
        ./wireguard.nix
    ];
    options.bgp = {
        enable = mkEnableOption "enable bgp";
        meta = mkOption {
            type = types.anything;
            description = "";
        };
        extraBirdConfig = mkOption {
            type = types.lines;
            default = "";
            description = "";
        };
        bgpSettings = let
            peer = types.submodule {
                options = {
                    name = mkOption {
                        type = types.str;
                        description = "";
                    };
                    endpoint = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "";
                    };
                    listen = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                        description = "listen port";
                    };
                    v4 = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "peer v4";
                    };
                    publicKey = mkOption {
                        type = types.str;
                        description = "wireguard public key";
                    };
                    presharedKeyFile = mkOption {
                        type = types.nullOr types.path;
                        default = null;
                        description = "wireguard preshared key file";
                    };
                    asn = mkOption {
                        type = types.str;
                        description = "";
                    };
                    linkLocal = mkOption {
                        type = types.str;
                        description = "peer link local address";
                    };
                    extendedNextHop = mkOption {
                        type = types.bool;
                        default = false;
                        description = "enable extended next hop";
                    };
                    refresh = mkOption {
                        type = types.int;
                        default = 0;
                        description = "dynamicEndpointRefreshSeconds";
                    };
                };
            };
        in {
            dn42 = {
                v4 = mkOption {
                    type = types.str;
                    description = "";
                };
                v6 = mkOption {
                    type = types.str;
                    description = "";
                };
                peers = mkOption {
                    type = types.listOf peer;
                    default = [];
                    description = "";
                };
            };
            internet = {
                peers = mkOption {
                    type = types.listOf peer;
                    default = [];
                    description = "";
                };
            };
        };
        bgpTransit = {
            enable = mkEnableOption "enable internet transit";
            asn = mkOption {
                type = types.str;
                description = "transit asn";
            };
            address = mkOption {
                type = types.str;
                description = "transit address";
            };
            password = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "bgp password";
            };
        };
    };
    config = mkIf cfg.enable {
        # bird-lg-go
        firewall.internalTCPPorts = [ 8000 ];
        services.bird-lg-go.enable = true;
    };
}