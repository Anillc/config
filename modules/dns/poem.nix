{ pkgs, lib, ... }: with lib; let
    repeat = n: elements: if n == 1 then elements
        else repeat (n - 1) ([ (builtins.elemAt elements 0) ] ++ elements);
    increase = n: elements: if n == 0 then elements
        else (increase (n - 1) elements) ++ [ n ];
in fix: text: let
    idn = builtins.readFile (pkgs.runCommand "domains" {} ''
        export CHARSET=UTF-8
        DOMAINS="${text}"
        ${pkgs.libidn}/bin/idn --quiet $DOMAINS > $out
    '');
    domains = strings.splitString "\n" (strings.removeSuffix "\n" idn);
    n = builtins.length domains;
in builtins.foldl' (acc: x: let
    numWithSpace = strings.splitString "" (toLower (toHexString x));
    num = sublist 1 ((builtins.length numWithSpace) - 2) numWithSpace;
    name = strings.concatStringsSep "." (num ++ (repeat (fix - (builtins.length num)) [ "0" ]));
in acc // {
    "${name}".PTR = [ "${builtins.elemAt domains (x - 1)}." ];
}) {} (increase n [])