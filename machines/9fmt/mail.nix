{ config, pkgs, lib, ... }:

{
    firewall.publicTCPPorts = [ 25 587 465 143 993 ];
    security.acme.certs."mail.anil.lc" = {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = "void@anil.lc";
    };
    mailserver = {
        enable = true;
        fqdn = "mail.anil.lc";
        domains = [ "anil.lc" ];
        localDnsResolver = false;
        # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
        loginAccounts = {
            "void@anil.lc" = {
                hashedPassword = "$2b$05$1vfB6EOTpq2H/ZfoNqxX/eQ43V2Zvg9f6yjGSyuFICZca98Zqjazm";
            };
        };
        certificateScheme = 3;
    };
    services.roundcube = {
        enable = true;
        hostName = "mail.anil.lc";
        extraConfig = ''
          $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
          $config['smtp_user'] = "%u";
          $config['smtp_pass'] = "%p";
        '';
    };
}