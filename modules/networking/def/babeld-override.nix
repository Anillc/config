# add -g 33123

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.babeld-override;

  conditionalBoolToString = value: if (isBool value) then (boolToString value) else (toString value);

  paramsString = params:
    concatMapStringsSep " " (name: "${name} ${conditionalBoolToString (getAttr name params)}")
                   (attrNames params);

  interfaceConfig = name:
    let
      interface = getAttr name cfg.interfaces;
    in
    "interface ${name} ${paramsString interface}\n";

  configFile = with cfg; pkgs.writeText "babeld.conf" (
    ''
      skip-kernel-setup true
    ''
    + (optionalString (cfg.interfaceDefaults != null) ''
      default ${paramsString cfg.interfaceDefaults}
    '')
    + (concatMapStrings interfaceConfig (attrNames cfg.interfaces))
    + extraConfig);

in

{

  meta.maintainers = with maintainers; [ hexa ];

  ###### interface

  options = {

    services.babeld-override = {

      enable = mkEnableOption "the babeld network routing daemon";

      interfaceDefaults = mkOption {
        default = null;
        description = ''
          A set describing default parameters for babeld interfaces.
          See <citerefentry><refentrytitle>babeld</refentrytitle><manvolnum>8</manvolnum></citerefentry> for options.
        '';
        type = types.nullOr (types.attrsOf types.unspecified);
        example =
          {
            type = "tunnel";
            split-horizon = true;
          };
      };

      interfaces = mkOption {
        default = {};
        description = ''
          A set describing babeld interfaces.
          See <citerefentry><refentrytitle>babeld</refentrytitle><manvolnum>8</manvolnum></citerefentry> for options.
        '';
        type = types.attrsOf (types.attrsOf types.unspecified);
        example =
          { enp0s2 =
            { type = "wired";
              hello-interval = 5;
              split-horizon = "auto";
            };
          };
      };

      extraConfig = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Options that will be copied to babeld.conf.
          See <citerefentry><refentrytitle>babeld</refentrytitle><manvolnum>8</manvolnum></citerefentry> for details.
        '';
      };
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    nixpkgs.overlays = [(self: super: {
      babeld = super.babeld.overrideAttrs (old: {
        src = pkgs.fetchgit {
          url = "https://github.com/jech/babeld.git";
          rev = "4b51a3b2ed6b5bbd331a8c127340cd4b38cc5d91";
          sha256 = "sha256-bogdBieNU3Dv922993yaVMEbrMn0Rt6n0VDONG1iJ08=";
         };
      });
    })];

    systemd.services.babeld = {
      description = "Babel routing daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.babeld}/bin/babeld -c ${configFile} -I /run/babeld/babeld.pid -S /var/lib/babeld/state -g 33123";
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        DevicePolicy = "closed";
        DynamicUser = true;
        IPAddressAllow = [ "fe80::/64" "ff00::/8" "::1/128" "127.0.0.0/8" ];
        IPAddressDeny = "any";
        LockPersonality = true;
        NoNewPrivileges = true;
        MemoryDenyWriteExecute = true;
        ProtectSystem = "strict";
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_NETLINK" "AF_INET6" "AF_INET" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = false; # kernel_route(ADD): Operation not permitted
        ProcSubset = "pid";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged @resources"
        ];
        UMask = "0177";
        RuntimeDirectory = "babeld";
        StateDirectory = "babeld";
      };
    };
  };
}