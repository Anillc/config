{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    inputs.nixpkgs-meilisearch.url = "github:NixOS/nixpkgs/d2003f2223cbb8cd95134e4a0541beea215c1073";
    # TODO: remove when bumped
    inputs.nixpkgs-new.url = "github:NixOS/nixpkgs/nixos-unstable";
    inputs.flake-utils.url = "github:numtide/flake-utils";
    inputs.anillc.url = "github:Anillc/flakes";
    inputs.chronocat-nix.url = "github:Anillc/chronocat.nix";
    inputs.nur.url = "github:nix-community/NUR";
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

    outputs = inputs@{
        self, nixpkgs, flake-utils, flake-parts, nur,
        sops-nix, deploy-rs, anillc, ...
    }: let
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
                pkgs.deploy-rs.deploy-rs pkgs.sops
                pkgs.step-cli pkgs.wireguard-tools
                (pkgs.writeScriptBin "run" (let
                    ms = pkgs.lib.filter (machine: machine.meta.enable) machines.list;
                    addresses = map (machine: "root@${machine.meta.address}") ms;
                    hosts = pkgs.lib.concatStringsSep " " addresses;
                in ''
                    #!${pkgs.runtimeShell}
                    export PATH=$PATH:${pkgs.lib.makeBinPath (with pkgs; [
                        pssh
                    ])}
                    pssh -H "${hosts}" --inline-stdout -p 100 "$@"
                ''))
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
                nur.modules.nixos.default
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