{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
    proxy = pkgs.buildGoModule {
      name = "proxy";
      src = pkgs.fetchFromGitHub {
        owner = "ilharp";
        repo = "captcha.koishi.xyz";
        rev = "699f0e84330f5f55c190313133435ca3f1eca076";
        sha256 = "sha256-uQfDMWOUKdpLdteArgUOy70xiHBw2uq7RZWaMEbSN4c=";
      };
      vendorSha256 = null;
    };
in {
    systemd.services.captcha-proxy = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig.Restart = "on-failure";
      script = "${proxy}/bin/captcha";
    };
    services.nginx = {
        enable = true;
        virtualHosts."captcha.koishi.xyz" = {
            enableACME = true;
            forceSSL = true;
            locations."/".proxyPass = "http://127.0.0.1:8081";
        };
    };
}