{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (hk.meta)  name wg-public-key; peer = 11002; cost = 1900; }
        { inherit (fmt.meta) name wg-public-key; peer = 11002; cost = 1300; }
    ];
}