{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    inputs.unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    inputs.flake-utils.url = "github:numtide/flake-utils";
    inputs.anillc.url = "github:Anillc/flakes";
    inputs.cllina.url = "github:Anillc/cllina";
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
    inputs.china-ip = {
        url = "github:gaoyifan/china-operator-ip/ip-lists";
        flake = false;
    };

    outputs = inputs@{ self, nixpkgs, unstable-nixpkgs, flake-utils, sops-nix, deploy-rs, anillc, ... }: let
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
        devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
                pkgs.deploy-rs.deploy-rs pkgs.sops pkgs.step-cli
                (pkgs.writeScriptBin "deploy-all" ''
                    nix build .#
                    deploy() {
                        # use stderr to avoid send build logs
                        ${pkgs.deploy-rs.deploy-rs}/bin/deploy -s --auto-rollback false .#$1 >/dev/stderr 2>&1
                        local status=$?
                        if [ $status -eq 0 ]; then
                            echo "deployed $1 successfully"
                        else
                            echo "error occured while deploying $1"
                        fi
                        message="$message$append"$'\n'
                    }
                    start() {
                        ms="${pkgs.lib.strings.concatStringsSep " " (map (machine: machine.meta.name) machines.list)}"
                        for m in $ms; do
                            deploy $m &
                        done
                        wait
                    }
                    message="message=$(start)"
                    $1 --data-urlencode "$message"
                '')
            ];
        };
    }) // (with builtins; with nixpkgs.lib; {
        systems = listToAttrs (map (machine: let
            inherit (machine) meta;
        in nameValuePair meta.name {
            inherit (meta) system;
            specialArgs = {
                inherit inputs;
                unstable-pkgs = import unstable-nixpkgs {
                    inherit (meta) system;
                };
            };
            modules = [
                sops-nix.nixosModules.sops
                anillc.nixosModules.${meta.system}.default
                modules
                machine.configuration
            ];
        }) machines.list);

        nixosConfigurations = mapAttrs (name: value: nixpkgs.lib.nixosSystem value) self.systems;

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