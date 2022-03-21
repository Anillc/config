lib: rec {
    machines = import ./.. lib;
    meta = {
        id = "06";
        name = "de";
        address = "de.an.dn42";
        inNat = true;
        wg-public-key = "JXN4fhKL5aRf++Bh1+xsAkVZPxZqaXuIcTXq2gS8ml8=";
        v4 = "172.22.167.102";
        v6 = "fdc9:83c1:d0ce::6";
        connect = with machines.set; [ lasvegas hongkong jp ];
    };
    configuration = { config, pkgs, ... }: {
        inherit meta;
        imports = [
            ./hardware.nix
            ./bgp.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;

        # firewall.publicTCPPorts = [ 646 ];
        # services.tinc.networks.fmt = {
        #     ed25519PrivateKeyFile = config.sops.secrets.tinc-private.path;
        #     interfaceType = "tap";
        #     settings = {
        #         Mode = "switch";
        #         DirectOnly = true;
        #     };
        #     hostSettings = {
        #         fmt = {
        #             addresses = [{ address = ""; port = 1655; }];
        #             settings = {
        #                 TCPOnly = "yes";
        #                 Ed25519PublicKey = "cONS4tKAwZYDB7mDEFRCqmeeuOodaTYRDT6PwOflvwP";
        #             };
        #         };
        #     };
        # };
        # services.frr.ldp = {
        #     enable = true;
        #     config = ''
        #         interface tinc.fmt
        #         interface lo
        #         mpls ldp
        #          dual-stack cisco-interop
        #          neighbor 192.168.156.1 password opensourcerouting
        #          address-family ipv4
        #           discovery transport-address 192.168.156.2
        #           label local advertise explicit-null
        #           interface tinc.fmt
        #         l2vpn ENG type vpls
        #          member pseudowire mpw0
        #           neighbor lsr-id 1.1.1.1
        #           pw-id 100
        #     '';
        # };
    };
}