{ ... }: {
    imports = [
        ./bind.nix
        ./dnsmasq.nix
    ];
    networking.nameservers = [ "172.22.167.125" ];
}