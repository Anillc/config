{ pkgs, config, lib, ... }: let
    intranet = import ./intranet.nix config pkgs;
    internet = import ./internet.nix config pkgs;
    dn42 = import ./dn42.nix config pkgs;
    keyToUnitName = lib.replaceChars
        [ "/" "-"    " "     "+"     "="      ]
        [ "-" "\\x2d" "\\x20" "\\x2b" "\\x3d" ];
in {
    config = lib.mkIf config.bgp.enable {
        networking.wireguard = {
            enable = true;
            interfaces = intranet // internet // dn42;
        };
        systemd.services = builtins.foldl' (acc: x: acc // (if x.meta.inNat then {} else {
            "wireguard-i${x.meta.name}-peer-${keyToUnitName x.meta.wg-public-key}" = {
                preStart = ''
                    ENDPOINT=$(${pkgs.jq}/bin/jq -r '."${x.meta.id}"' ${config.sops.secrets.endpoints.path})
                    ${pkgs.wireguard-tools}/bin/wg set i${x.meta.name} peer "${x.meta.wg-public-key}" endpoint "$ENDPOINT:110${config.bgp.meta.id}"
                '';
            };
        }) // {
            "wireguard-i${x.meta.name}" = {
                requiredBy = [ "babeld.service" ];
            };
        }) {} config.bgp.connect;
    };
}