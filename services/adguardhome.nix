{config, pkgs, ...}:
{
  ## Firewall Rules
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  ## Adguard Home
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      https.address = "127.0.0.1:3000";
      filtering.rewrites = [
        { domain = "*.archongrid.xyz"; answer = "192.168.1.217"; enabled = true; }
        { domain = "archongrid.xyz";   answer = "192.168.1.217"; enabled = true; }
      ];
      dns = {
        bind_hosts = [ "192.168.1.217" "127.0.0.1" ];
        upstream_dns = [ "https://dns.cloudflare.com/dns-query" "tls://dns.quad9.net" ];
        bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
      };
    };
  };
}