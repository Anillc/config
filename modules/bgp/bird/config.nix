pkgs: cfg: ''
    # log "/var/bird/bird.log" all;
    router id 10.127.20.1${cfg.meta.id};
    protocol device {
        scan time 10;
    }
    protocol kernel {
        scan time 20;
        learn;
        ipv4 {
            import all;
            export all;
        };
    }
    protocol kernel {
        scan time 20;
        learn;
        ipv6 {
            import all;
            export all;
        };
    }

    define DN42_ASN = 4242422526;
    define INTERNET_ASN = 142055;
    define INTRANET_ASN = 142055;

    define DN42_SRC_v4 = ${cfg.bgpSettings.dn42.v4};
    define DN42_SRC_v6 = ${cfg.bgpSettings.dn42.v6};
    define INTERNET_SRC_v4 = 0.0.0.0;
    define INTERNET_SRC_v6 = 2602:feda:da0::${cfg.meta.id};

    include "/var/bird/ptp.conf";
    ${import ./utils.nix}
    ${import ./networks/dn42.nix pkgs cfg}
    ${import ./networks/internet.nix cfg}
    ${import ./networks/intranet.nix pkgs cfg}

    ${import ./static.nix}
''