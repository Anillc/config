{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    inputs.flake-utils.url = "github:numtide/flake-utils";
    inputs.anillc.url = "github:Anillc/flakes";
    inputs.sops-nix = {
        url = "github:Mic92/sops-nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.deploy-rs = {
        url = "github:serokell/deploy-rs";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.dns = {
        url = "github:kirelagin/dns.nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.nixos-cn = {
        url = "github:nixos-cn/flakes";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.china-ip = {
        url = "github:17mon/china_ip_list";
        flake = false;
    };

    outputs = { self, nixpkgs, flake-utils, sops-nix, deploy-rs, anillc, dns, nixos-cn, china-ip }: let
        machines = import ./machines nixpkgs.lib;
        modules = import ./modules;
    in flake-utils.lib.eachDefaultSystem (system: let 
        pkgs = import nixpkgs {
            inherit system;
            overlays = [
                deploy-rs.overlay
            ];
        };
    in {
        packages.default = pkgs.stdenv.mkDerivation {
            name = "machines";
            propagatedBuildInputs = pkgs.lib.mapAttrsToList (name: value:
                value.config.system.build.toplevel) self.nixosConfigurations;
            unpackPhase = ":";
            installPhase = "mkdir -p $out";
        };
        devShell = pkgs.mkShell {
            nativeBuildInputs = [
                pkgs.deploy-rs.deploy-rs pkgs.sops pkgs.step-cli
                (pkgs.writeScriptBin "deploy-all" ''
                    nix build .#
                    deploy() {
                        log=$(${pkgs.deploy-rs.deploy-rs}/bin/deploy -s --auto-rollback false .#$1 2>&1)
                        echo $log
                    }
                    ms="${pkgs.lib.strings.concatStringsSep " " (map (machine: machine.meta.name) machines.list)}"
                    for m in $ms; do
                        deploy $m &
                    done
                    wait
                '')
            ];
        };
    }) // (with builtins; with nixpkgs.lib; {
        nixosConfigurations = listToAttrs (map (machine: let
            inherit (machine) meta;
        in nameValuePair meta.name (nixpkgs.lib.nixosSystem {
            inherit (meta) system;
            modules = [
                { nixpkgs.overlays = [(self: super: {
                    inherit nixpkgs dns china-ip;
                })]; }
                sops-nix.nixosModules.sops
                anillc.nixosModules.${meta.system}.default
                nixos-cn.nixosModules.nixos-cn
                modules
                machine.configuration
            ];
        })) machines.list);

        deploy.nodes = listToAttrs (map (machine: let
            inherit (machine) meta;
        in nameValuePair meta.name {
            sshUser = "root";
            hostname = meta.address;
            confirmTimeout = 300;
            profiles.system.path = deploy-rs.lib.${meta.system}.activate.nixos self.nixosConfigurations.${meta.name};
        }) (filter (machine: machine.meta.enable) machines.list));
    });
}