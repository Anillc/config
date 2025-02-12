{ lib, writeText, sing-geoip, sing-geosite, nur }:

writeText "config.json" (lib.generators.toJSON {} {
  route.rule_set = [
    {
      type = "local";
      tag = "s_geoip-cn";
      format = "binary";
      path = "${sing-geoip}/share/sing-box/rule-set/geoip-cn.srs";
    }
    {
      type = "local";
      tag = "s_geosite-cn";
      format = "binary";
      path = "${sing-geosite}/share/sing-box/rule-set/geosite-cn.srs";
    }
  ];
  experimental.clash_api = {
    external_controller = "0.0.0.0:9090";
    external_ui = nur.repos.linyinfeng.yacd;
  };

  dns = {
    servers = [
      { tag = "s_google"; address = "tls://8.8.8.8"; }
      { tag = "s_local"; address = "udp://10.11.1.2"; detour = "s_direct"; }
    ];
    rules = [
      { domain_suffix = ".a"; server = "s_local"; }
      { outbound = "s_select"; server = "s_google"; }
    ];
    final = "s_local";
  };

  inbounds = [
    {
      type = "tproxy";
      tag = "s_tproxy-in";
      listen_port = 9898;
    }
  ];

  outbounds = [
    { type = "direct"; tag = "s_direct"; }
    {
      type = "selector";
      tag = "s_select";
      outbounds = [ "auto" "s_direct" ];
      default = "auto";
    }
  ];

  route = {
    rules = [
      { action = "sniff"; }
      { action =  "hijack-dns"; protocol = "dns"; }
      { rule_set = "s_geoip-cn"; outbound = "s_direct"; }
      { rule_set = "s_geosite-cn"; outbound = "s_direct"; }
      { ip_is_private = true; outbound = "s_direct"; }
    ];
    final = "s_select";
    auto_detect_interface = true;
  };
})
