{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    inputs.flake-utils.url = "github:numtide/flake-utils";
    inputs.anillc.url = "github:Anillc/flakes";
    inputs.chronocat.url = "github:Anillc/chronocat.nix";
    inputs.koinix.url = "github:Anillc/koinix";
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

    outputs = inputs@{ self, nixpkgs, flake-utils, sops-nix, deploy-rs, anillc, ... }: let
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
            ];
        };
    }) // (with builtins; with nixpkgs.lib; {
        systems = listToAttrs (map (machine: let
            inherit (machine) meta;
        in nameValuePair meta.name {
            inherit (meta) system;
            specialArgs = { inherit inputs; };
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