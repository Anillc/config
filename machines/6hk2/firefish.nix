{ config, ... }:

{
    services.postgresql = {
        enable = true;
        enableTCPIP = true;
        ensureDatabases = [ "firefish" ];
        ensureUsers = [{
            name = "firefish";
            ensurePermissions = {
                "DATABASE firefish" = "ALL PRIVILEGES";
            };
        }];
        authentication = ''
            host   all      firefish 127.0.0.1/32   trust
            host   all      firefish ::1/128        trust
            local  all      firefish trust
        '';
    };
    services.redis.servers.firefish = {
        enable = true;
        port = 6379;
    };
    virtualisation.oci-containers = {
        backend = "podman";
        containers.firefish = {
            image = "registry.joinfirefish.org/firefish/firefish";
            extraOptions = [ "--network=host" ];
            volumes = [
                "/var/lib/firefish/files:/firefish/files"
                "${config.sops.secrets.firefish.path}:/firefish/.config/default.yml"
            ];
        };
    };
    systemd.tmpfiles.rules = [
        "d /var/lib/firefish/files - - - -"
    ];
}