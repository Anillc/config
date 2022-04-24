{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    sops.secrets.jwk-key.sopsFile = ./secrets.yaml;
    services.openssh.startWhenNeeded = false;
    systemd.services.sshd.preStart = mkAfter (flip concatMapStrings config.services.openssh.hostKeys (x: ''
        if [ -s "${x.path}.pub" ]; then
            ${pkgs.step-cli}/bin/step ssh certificate ${config.meta.name} ${x.path}.pub \
                --host --sign --ca-url https://ca.a \
                --root ${./root_ca.crt} \
                --provisioner jwk --provisioner-password-file ${config.sops.secrets.jwk-key.path} \
                --principal ${config.meta.domain} \
                --force
        fi
    ''));
    services.openssh.extraConfig = ''
        TrustedUserCAKeys ${./ssh_user_ca.pub}
    '' + flip concatMapStrings config.services.openssh.hostKeys (x: ''
        HostCertificate ${x.path}-cert.pub
    '');
}