let
    files = builtins.attrNames (removeAttrs (builtins.readDir ./.) [ "default.nix" ]);
in rec {
    set = builtins.foldl' (acc: x: acc // (let
        machine = import ./${x};
    in {
        "${machine.meta.name}" = machine;
    })) {} files;
    list = builtins.attrValues set;
    validate = evalModules: machine: (evalModules {
        modules = [
            ../modules/common/meta.nix
            { inherit (machine) meta; }
        ];
    }).config.meta;
    metas = evalModules: builtins.map (validate evalModules) list;
}