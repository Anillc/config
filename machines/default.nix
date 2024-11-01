lib:

with builtins;
with lib;

let
    validate = machine: (evalModules {
        modules = [
            ../modules/common/meta.nix
            { cfg.meta = machine.meta; }
        ];
    }).config.cfg.meta;

    folders = attrNames (removeAttrs (readDir ./.) [ "default.nix" ]);
    machines = listToAttrs (map (folder: let
        machine = import ./${folder};
        meta = validate machine;
    in nameValuePair meta.name (machine // {
        inherit meta;
    })) folders);
in rec {
    set = machines;
    list = attrValues set;
}