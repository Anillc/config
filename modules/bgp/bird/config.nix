pkgs: config: ''
    # log "/var/bird/bird.log" all;
    router id 10.127.20.1${config.bgp.meta.id};
    protocol device {
        scan time 10;
    }
    protocol kernel {
        scan time 20;
        learn;
        ipv4 {
            import filter {
                # igp metric
                babel_metric = krt_metric;
                accept;
            };
            export all;
        };
    }
    protocol kernel {
        scan time 20;
        learn;
        ipv6 {
            import filter {
                # igp metric
                babel_metric = krt_metric;
                accept;
            };
            export all;
        };
    }

    define DN42_ASN = 4242422526;
    define INTERNET_ASN = 142055;
    define INTRANET_ASN = 142055;

    define DN42_SRC_v4 = ${config.bgp.bgpSettings.dn42.v4};
    define DN42_SRC_v6 = ${config.bgp.bgpSettings.dn42.v6};
    define INTERNET_SRC_v4 = 0.0.0.0;
    define INTERNET_SRC_v6 = 2602:feda:da0::${config.bgp.meta.id};

    include "${config.sops.secrets.bird-conf.path}";
    ${import ./utils.nix}
    ${import ./networks/dn42.nix pkgs config.bgp}
    ${import ./networks/internet.nix config.bgp}
    ${import ./networks/intranet.nix pkgs config.bgp}

    ${import ./static.nix}
''