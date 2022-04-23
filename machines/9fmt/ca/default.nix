{ config, pkgs, lib, ... }:

with builtins;
with lib;

{
    services.step-ca = {
        enable = true;
        address = "";
        port = 8443;
        intermediatePasswordFile = config.sops.secrets.ca-key.path;
        settings = {
            root = "${./root_ca.crt}";
            federatedRoots = null;
            crt = "${./intermediate_ca.crt}";
            key = "${./intermediate_ca_key}";
            insecureAddress = "";
            dnsNames = [
                "ca.a"
                "10.11.0.9"
                "fd11::9"
            ];
            logger.format = "text";
            db = {
                type = "badgerv2";
                dataSource = "/var/lib/step-ca/db";
                badgerFileLoadingMode = "";
            };
            authority = {
                provisioners = [{
                    type = "ACME";
                    name = "acme";
                }];
                template = {};
                backdate = "1m0s";
            };
            tls = {
                cipherSuites = [
                    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
                    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                ];
                minVersion = 1.2;
                maxVersion = 1.3;
                renegotiation = false;
            };
        };
    };
}