lib:

with builtins;
with lib;

let
    validate = machine: (evalModules {
        modules = [
            ../modules/common/meta.nix
            { inherit (machine) meta; }
        ];
    }).config.meta;

    folders = attrNames (removeAttrs (readDir ./.) [ "default.nix" ]);
    machines = listToAttrs (map (folder: let
        machine = import ./${folder} lib;
        meta = validate machine;
    in nameValuePair meta.name (machine // {
        inherit meta;
    })) folders);
in rec {
    set = machines;
    list = attrValues set;
}