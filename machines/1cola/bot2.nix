{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    containers.bot2 = {
        autoStart = true;
        bindMounts."/run/secrets" = {};
        config = {
            imports = [ inputs.anillc.nixosModules.${pkgs.system}.default ];
            system.stateVersion = "22.05";
            documentation.enable = false;
            security.pki.certificates = mkForce config.security.pki.certificates;
            networking.firewall.enable = false;
            services.go-cqhttp = {
                enable = true;
                device = config.sops.secrets.anillc-device.path;
                environmentFile = config.sops.secrets.anillc-environment.path;
                config = {
                    message = {
                        remove-reply-at = true;
                        skip-mime-scan = true;
                    };
                    account = {
                        uin = "\${UIN}";
                        password = "\${PASSWORD}";
                    };
                    servers = mkForce [{
                        ws = {
                            host = "0.0.0.0";
                            port = 6701;
                        };
                    }];
                };
            };
        };
    };
}