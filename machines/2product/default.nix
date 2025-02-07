rec {
    meta = {
        id = 2;
        name = "product";
        wg-public-key = "lLWnD8LKlAhtiHJM99cfyvDZkueqmNAaFweEmbKx1SM=";
        syncthingId = "BIRJK3L-GAPKYXE-MAYAHJK-QIZVRBE-SRVGTG6-43PT6O5-VYAU6KZ-4JMCHA4";
    };
    configuration = { config, pkgs, lib, ... }: {
        cfg.meta = meta;
        imports = [
            ./hardware.nix
            ./networking.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        nix.settings.substituters = lib.mkBefore [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
    };
}