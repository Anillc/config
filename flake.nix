{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #inputs.nixpkgs.url = "git+file:///home/anillc/nixpkgs";
    #inputs.nixpkgs.url = "github:Anillc/nixpkgs";
    inputs.flake-utils = {
        url = "github:numtide/flake-utils";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.sops-nix = {
        url = "github:Mic92/sops-nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.deploy-rs = {
        url = "github:serokell/deploy-rs";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.anillc = {
        url = "github:Anillc/flakes";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.dns = {
        url = "github:kirelagin/dns.nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, flake-utils, sops-nix, deploy-rs, anillc, dns }: let
        m = import ./machines;
        machineSet = m.set;
        metas = m.metas nixpkgs.lib.evalModules;
    in flake-utils.lib.eachDefaultSystem (system: let 
        pkgs = import nixpkgs {
            overlays = [ deploy-rs.overlay ];
            inherit system;
        };
    in {
        devShell = pkgs.mkShell {
            nativeBuildInputs = [
                pkgs.deploy-rs.deploy-rs pkgs.sops
                (pkgs.writeScriptBin "deploy-all" ''
                    deploy() {
                        log=$(${pkgs.deploy-rs.deploy-rs}/bin/deploy -s .#$1 2>&1)
                        echo $log
                    }
                    ms="${pkgs.lib.strings.concatStringsSep " " (builtins.map (x: x.name) metas)}"
                    for m in $ms; do
                        deploy $m &
                        pids[$!]=$!
                    done
                    for pid in ''${pids[*]}; do
                        wait $pid
                    done
                '')
            ];
        };
    }) // {
        nixosConfigurations = builtins.foldl' (acc: x: acc // {
            "${x.name}" = nixpkgs.lib.nixosSystem {
            modules = [
                sops-nix.nixosModules.sops
                anillc.nixosModule.${x.system}
                ({...}: { nixpkgs.overlays = [ (_: _: {
                    inherit dns;
                }) ]; })
                (import ./modules)
                machineSet.${x.name}.configuration
            ];
            inherit (x) system;
        };
        }) {} metas;
        deploy.nodes = builtins.foldl' (acc: x: if !x.enable then acc else acc // {
            "${x.name}" = {
                sshUser = "root";
                sshOpts = [ "-4" "-o" "ServerAliveInterval=30" "-o" "StrictHostKeyChecking=no" ];
                hostname = x.address;
                confirmTimeout = 300;
                profiles.system.path = deploy-rs.lib.${x.system}.activate.nixos self.nixosConfigurations.${x.name};
            };
        }) {} metas;
    };
}