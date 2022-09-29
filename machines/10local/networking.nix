{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    machines = import ./.. lib;
in {
    wgi = with machines.set; [
        { inherit (sh.meta) name wg-public-key; peer = 11010; cost = 200; }
        { inherit (hk.meta) name wg-public-key; peer = 11010; cost = 400; }
    ];
}