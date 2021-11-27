{ pkgs, ... }: {
    services.asterisk = {
        enable = true;
        confFiles."modules.conf" = ''
            [modules]
            autoload=yes
            noload => chan_sip.so
        '';
        confFiles."pjsip.conf" = ''
            [global]
            type=global

            [transport4]
            type=transport
            protocol=udp
            bind=0.0.0.0:5060

            [transport6]
            type=transport
            protocol=udp
            bind=[::]:5060

            ;=============TEMPLATE==============

            [endpoint-template](!)
            type=endpoint
            context=mydialcontext
            allow=!all,ulaw,speex,alaw
            rtp_symmetric=no
            force_rport=yes
            rewrite_contact=yes

            [auth-template](!)
            type=auth

            [aor-template](!)
            type=aor
            max_contacts=1
            remove_existing=yes

            ;=============PHONES==============

            [Anillc](endpoint-template)
            auth = Anillc
            aors = Anillc
            callerid=Anillc <424025260001>
            [Anillc](auth-template)
            auth_type=userpass
            username=Anillc
            password=233
            [Anillc](aor-template)

            ;=============PEERS==============

            [yang](endpoint-template)
            aors=yang
            identify_by=ip
            [yang](aor-template)
            contact=sip:172.20.168.194:5060
            [yang]
            type=identify
            endpoint=yang
            match=172.20.168.194

            [hertz](endpoint-template)
            aors=hertz
            identify_by=ip
            [hertz](aor-template)
            contact=sip:172.20.29.73:5060
            [hertz]
            type=identify
            endpoint=hertz
            match=172.20.29.73
        '';
        confFiles."extensions.conf" = ''
            [general]
            static=yes
            writeprotect=no
            clearglobalvars=no

            [mydialcontext]
            exten => _XXXX,1,Goto(42402526''${EXTEN},1)
            exten => _XXXXXXXX,1,Goto(4240''${EXTEN},1)
            exten => _XXXXXXXXX,1,Goto(424''${EXTEN},1)
            exten => _X.,1,NoOp()

            exten => _42402526XXXX,2,Answer()

            exten => 424025260000,3,Playback(silence/1&hello-world&silence/1)

            exten => 424025260001,3,Dial(PJSIP/Anillc)

            exten => _42402526XXXX,3,Playback(im-sorry&check-number-dial-again)

            exten => _42401332XXXX,2,Dial(PJSIP/''${EXTEN}@yang)
            exten => _4242421353XXXX,2,Dial(PJSIP/''${EXTEN}@hertz)
        '';
    };
}