let
    files = builtins.attrNames (removeAttrs (builtins.readDir ./.) [ "default.nix" ]);
in rec {
    set = builtins.foldl' (acc: x: acc // (let
        machine = import ./${x};
    in {
        "${machine.meta.name}" = machine;
    })) {} files;
    list = builtins.attrValues set;
}