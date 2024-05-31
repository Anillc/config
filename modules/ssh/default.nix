{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    sops.secrets.jwk-key.sopsFile = ./secrets.yaml;
    services.openssh.startWhenNeeded = false;
    security.acme = {
        defaults = {
            server = "https://ca.a:8443/acme/acme/directory";
            email = "acme@a";
            renewInterval = "00/8:00";
        };
        acceptTerms = true;
    };
    systemd.timers.ssh-cert = {
        wantedBy = [ "timers.target" ];
        partOf = [ "setup-wireguard.service" ];
        timerConfig = {
            OnCalendar = "00/8:00";
            Unit = "ssh-cert.service";
            Persistent = true;
        };
    };
    systemd.services = {
        ssh-cert = {
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            path = with pkgs; [ step-cli ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "-${pkgs.writeScript "ssh-cert" (flip concatMapStrings config.services.openssh.hostKeys (x: ''
                    #!${pkgs.runtimeShell}
                    step ssh certificate ${config.meta.name} ${x.path}.pub \
                        --host --sign --ca-url https://ca.a \
                        --root ${./root_ca.crt} \
                        --provisioner jwk --provisioner-password-file ${config.sops.secrets.jwk-key.path} \
                        --principal ${config.meta.domain} \
                        --principal ${config.meta.name} \
                        --force
                ''))}";
            };
        };
    } // mapAttrs' (name: value: nameValuePair "acme-${name}" {
        # FIXME
        # serviceConfig.Restart = "on-failure";
    }) config.security.acme.certs;
    services.openssh.extraConfig = ''
        TrustedUserCAKeys ${./ssh_user_ca.pub}
    '' + flip concatMapStrings config.services.openssh.hostKeys (x: ''
        HostCertificate ${x.path}-cert.pub
    '');
}