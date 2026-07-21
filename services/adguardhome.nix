{config, pkgs, ...}:
{
  ## Firewall Rules
  # networking.firewall.allowedTCPPorts = [ 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];

  ## Adguard Home
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      http.address = "100.76.83.76:3000";
      filtering.rewrites = [
        { domain = "*.archongrid.xyz"; answer = "100.76.83.76"; enabled = true; }
        { domain = "archongrid.xyz";   answer = "100.76.83.76"; enabled = true; }
      ];
      dns = {
        bind_hosts = [ "100.76.83.76" "127.0.0.1" ];
        upstream_dns = [ "https://dns.cloudflare.com/dns-query" "tls://dns.quad9.net" ];
        bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
      };
    };
  };
  
}
