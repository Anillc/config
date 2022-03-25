# support rpki

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.frr-override;
  package = pkgs.frr.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [
          "--enable-rpki"
      ];
      buildInputs = old.buildInputs ++ [ pkgs.rtrlib ];
  });

  services = [
    "static"
    "bgp"
    "ospf"
    "ospf6"
    "rip"
    "ripng"
    "isis"
    "pim"
    "ldp"
    "nhrp"
    "eigrp"
    "babel"
    "sharp"
    "pbr"
    "bfd"
    "fabric"
  ];

  allServices = services ++ [ "zebra" ];

  isEnabled = service: cfg.${service}.enable;

  daemonName = service: if service == "zebra" then service else "${service}d";

  configFile = service:
    let
      scfg = cfg.${service};
    in
      if scfg.configFile != null then scfg.configFile
      else pkgs.writeText "${daemonName service}.conf"
        ''
          ! FRR ${daemonName service} configuration
          !
          hostname ${config.networking.hostName}
          log syslog
          service password-encryption
          !
          ${scfg.config}
          !
          end
        '';

  serviceOptions = service:
    {
      enable = mkEnableOption "the FRR ${toUpper service} routing protocol";

      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/etc/frr/${daemonName service}.conf";
        description = ''
          Configuration file to use for FRR ${daemonName service}.
          By default the NixOS generated files are used.
        '';
      };

      config = mkOption {
        type = types.lines;
        default = "";
        example =
          let
            examples = {
              rip = ''
                router rip
                  network 10.0.0.0/8
              '';

              ospf = ''
                router ospf
                  network 10.0.0.0/8 area 0
              '';

              bgp = ''
                router bgp 65001
                  neighbor 10.0.0.1 remote-as 65001
              '';
            };
          in
            examples.${service} or "";
        description = ''
          ${daemonName service} configuration statements.
        '';
      };

      vtyListenAddress = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          Address to bind to for the VTY interface.
        '';
      };

      vtyListenPort = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          TCP Port to bind to for the VTY interface.
        '';
      };

      extraOptions = mkOption {
          type = types.str;
          default = "";
          description = ''
            Extra options needed by those like bgp rpki.
          '';
      };
    };

in

{

  ###### interface
  imports = [
    {
      options.services.frr-override = {
        zebra = (serviceOptions "zebra") // {
          enable = mkOption {
            type = types.bool;
            default = any isEnabled services;
            description = ''
              Whether to enable the Zebra routing manager.
              The Zebra routing manager is automatically enabled
              if any routing protocols are configured.
            '';
          };
        };
      };
    }
    { options.services.frr-override = (genAttrs services serviceOptions); }
  ];

  ###### implementation

  config = mkIf (any isEnabled allServices) {

    environment.systemPackages = [
      package # for the vtysh tool
    ];

    users.users.frr = {
      description = "FRR daemon user";
      isSystemUser = true;
      group = "frr";
    };

    users.groups = {
      frr = {};
      # Members of the frrvty group can use vtysh to inspect the FRR daemons
      frrvty = { members = [ "frr" ]; };
    };

    environment.etc = let
      mkEtcLink = service: {
        name = "frr/${service}.conf";
        value.source = configFile service;
      };
    in
      (builtins.listToAttrs
      (map mkEtcLink (filter isEnabled allServices))) // {
        "frr/vtysh.conf".text = "";
      };

    systemd.tmpfiles.rules = [
      "d /run/frr 0750 frr frr -"
    ];

    systemd.services =
      let
        frrService = service:
          let
            scfg = cfg.${service};
            daemon = daemonName service;
          in
            nameValuePair daemon ({
              wantedBy = [ "multi-user.target" ];
              after = [ "network-pre.target" "systemd-sysctl.service" ] ++ lib.optionals (service != "zebra") [ "zebra.service" ];
              bindsTo = lib.optionals (service != "zebra") [ "zebra.service" ];
              wants = [ "network.target" ];

              description = if service == "zebra" then "FRR Zebra routing manager"
                else "FRR ${toUpper service} routing daemon";

              unitConfig.Documentation = if service == "zebra" then "man:zebra(8)"
                else "man:${daemon}(8) man:zebra(8)";

              restartTriggers = [
                (configFile service)
              ];
              reloadIfChanged = true;

              serviceConfig = {
                PIDFile = "frr/${daemon}.pid";
                ExecStart = "${package}/libexec/frr/${daemon} -f /etc/frr/${service}.conf"
                  + optionalString (scfg.vtyListenAddress != "") " -A ${scfg.vtyListenAddress}"
                  + optionalString (scfg.vtyListenPort != null) " -P ${toString scfg.vtyListenPort}"
                  + " " + scfg.extraOptions;
                ExecReload = "${pkgs.python3.interpreter} ${package}/libexec/frr/frr-reload.py --reload --daemon ${daemonName service} --bindir ${package}/bin --rundir /run/frr /etc/frr/${service}.conf";
                Restart = "on-abnormal";
              };
            });
       in
         listToAttrs (map frrService (filter isEnabled allServices));

  };

  meta.maintainers = with lib.maintainers; [ woffs ];

}