{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
    services.go-cqhttp = {
        enable = true;
        device = config.sops.secrets.cllina-device.path;
        environmentFile = config.sops.secrets.cllina-environment.path;
        config = {
            message = {
                remove-reply-at = true;
                skip-mime-scan = true;
            };
            account = {
                uin = "\${UIN}";
                password = "\${PASSWORD}";
            };
        };
    };
    # TODO: pma and selfUrl
    # virtualisation.oci-containers = {
    #     backend = "podman";
    #     containers.pma = {
    #         image = "docker.io/library/phpmyadmin";
    #         volumes = [
    #             "/run/mysqld/mysqld.sock:/tmp/mysql.sock"
    #         ];
    #         environment = {
    #             PMA_HOST = "localhost";
    #         };
    #         ports = [ "8444:80" ];
    #     };
    # };
}