_: let
    files = builtins.attrNames (removeAttrs (builtins.readDir ./.) [ "default.nix" ]);
in {
    imports = map (name: ./${name}) files;
}