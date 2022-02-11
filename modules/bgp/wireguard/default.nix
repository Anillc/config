{ pkgs, config, lib, ... }: let
    intranet = import ./intranet.nix config pkgs;
    internet = import ./internet.nix config pkgs;
    dn42 = import ./dn42.nix config pkgs;
    keyToUnitName = lib.replaceChars
        [ "/" "-"    " "     "+"     "="      ]
        [ "-" "\\x2d" "\\x20" "\\x2b" "\\x3d" ];
in {
    config = lib.mkIf config.bgp.enable {
    };
}