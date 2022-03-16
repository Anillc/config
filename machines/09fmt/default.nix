rec {
    machines = (import ./..).set;
    meta = {
        id = "09";
        name = "fmt";
        address = "fmt.an.dn42";
        wg-public-key = "3jCbL/4+/Sdk2NuDQGln09AKj8v29GnxyS/0WSzJ0Ck=";
        v4 = "172.22.167.108";
        v6 = "fdc9:83c1:d0ce::12";
        connect = [ machines.lasvegas ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        firewall.publicTCPPorts = [ 1655 646 ];
        # services.tinc.networks.de = {
        #     ed25519PrivateKeyFile = config.sops.secrets.tinc-private.path;
        #     interfaceType = "tap";
        #     bindToAddress = "0.0.0.0 1655";
        #     settings = {
        #         Mode = "switch";
        #         DirectOnly = true;
        #     };
        #     hostSettings = {
        #         de = {
        #             settings = {
        #                 TCPOnly = true;
        #                 Ed25519PublicKey = "cONS4tKAwZYDB7mDEFRCqmeeuOodaTYRDT6PwOflvwP";
        #             };
        #         };
        #     };
        # };
        # services.frr.ldp = {
        #     enable = true;
        #     config = ''
        #         mpls ldp
        #          dual-stack cisco-interop
        #          neighbor 192.168.156.2 password opensourcerouting
        #          address-family ipv4
        #           discovery transport-address 192.168.156.1
        #           label local advertise explicit-null
        #           interface tinc.de
        #         l2vpn ENG type vpls
        #          member pseudowire mpw0
        #           neighbor lsr-id 192.168.156.2
        #           pw-id 100
        #     '';
        # };
    };
}