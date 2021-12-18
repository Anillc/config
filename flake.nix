{
    description = "config";

    #inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #inputs.nixpkgs.url = "git+file:///home/anillc/nixpkgs";
    inputs.nixpkgs.url = "github:Anillc/nixpkgs";
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
        machines = (import ./machines).list;
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
                    ms="${builtins.foldl' (acc: x: acc + x.meta.name + " ") "" machines}"
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
            "${x.meta.name}" = nixpkgs.lib.nixosSystem {
            modules = [
                sops-nix.nixosModules.sops
                anillc.nixosModule.${x.meta.system}
                ({...}: { nixpkgs.overlays = [ (_: _: {
                    inherit dns;
                }) ]; })
                (import ./modules)
                x.configuration
            ];
            inherit (x.meta) system;
        };
        }) {} machines;
        deploy.nodes = builtins.foldl' (acc: x: acc // {
            "${x.meta.name}" = {
                sshUser = "root";
                sshOpts = [ "-4" "-o" "ServerAliveInterval=30" "-o" "StrictHostKeyChecking=no" ];
                hostname = x.meta.address;
                confirmTimeout = 300;
                profiles.system.path = deploy-rs.lib.${x.meta.system}.activate.nixos self.nixosConfigurations.${x.meta.name};
            };
        }) {} machines;
    };
}