{ ... }: {
    imports = [
        ./knot.nix
        ./dnsmasq.nix
    ];
    networking.nameservers = [ "10.11.1.2" ];
}