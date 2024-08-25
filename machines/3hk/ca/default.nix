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
                "10.11.0.3"
                "fd11::3"
            ];
            ssh = {
                hostKey = "${./ssh_host_ca_key}";
                userKey = "${./ssh_user_ca_key}";
            };
            logger.format = "text";
            db = {
                type = "badgerv2";
                dataSource = "/var/lib/step-ca/db";
                badgerFileLoadingMode = "";
            };
            authority = {
                provisioners = [
                    {
                        type = "JWK";
                        name = "jwk";
                        key = {
                            use = "sig";
                            kty = "EC";
                            kid = "IxDL9ycKkx7kIw2sGj5haoSNrgRmx5wq3lH5aiOqdf0";
                            crv = "P-256";
                            alg = "ES256";
                            x = "h2WOr7rKk4DQLmS09e4mivHRlyF-pfzw_Snmax94l1c";
                            y = "ga7ysiBb7ulxMn7xZieSLwPODFkektNnUdzP70Ucu-4";
                        };
                        encryptedKey = "eyJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1ciLCJjdHkiOiJqd2sranNvbiIsImVuYyI6IkEyNTZHQ00iLCJwMmMiOjEwMDAwMCwicDJzIjoibko0aDh5M1lTSUxfYU0tWFBxN1lZQSJ9.Fqpmph5fUXIjmpZJvwyvicMqJGli0gO285FdV6IfWyqlhZPz2OG_Pg.EN7_lzhVf2yqxqS0.kldVPqzKFT7DQuhhTrMt736EBp6fxcjrjUZJNGqKET1SS8YkZaLxsTgFWOhv5TVubt7b4p1CVM-hirz1ESp7VVeV08g2wWHeSUPvQOo1GZP9QVKrEjJmMt2BCna6mlYG2X36h5v31MPK0TuMvfJP5FWgCm17fDTpKfMZPdegWjPrqkonPciHm2VfymQelPg3O-n6_GunGsfbpmoUFSN7TL5sif20e60rDaSl_zAxrG4eDp2jK6BEyO7mVTwUPTqduvYTiByLC0OcwtDdntPM2dRPAS-PQDiUwQbMqbTmo83F5WSvwWj-CfLeH73MDhITEk1I6ShzpXqaaFUnNc0.3KjPXh5tIBuzr07W--kR7A";
                        claims = {
                            enableSSHCA = true;
                            maxUserSSHCertDuration = "0m0s";
                        };
                    }
                    {
                        type = "ACME";
                        name = "acme";
                    }
                ];
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