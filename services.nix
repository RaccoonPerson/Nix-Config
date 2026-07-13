{ config, pkgs, lib, ... }:
{
  # 53 udp/tcp for adguard
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  # services.adguardhome = {
  #   enable = true;
  #   mutableSettings = false;
  #   settings = {
  #     https.address = "127.0.0.1:3000";
  #     filtering.rewrites = [
  #       { domain = "*.archongrid.xyz"; answer = "192.168.1.217"; enabled = true; }
  #       { domain = "archongrid.xyz";   answer = "192.168.1.217"; enabled = true; }
  #     ];
  #     dns = {
  #       bind_hosts = [ "192.168.1.217" "127.0.0.1" ];
  #       upstream_dns = [ "https://dns.cloudflare.com/dns-query" "tls://dns.quad9.net" ];
  #       bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
  #     };
  #   };
  # }; # Does not have username or pswd, do not uncomment before setting that

  services.caddy = {
    enable = true;
    virtualHosts = {
      "cloud.archongrid.xyz".extraConfig = ''
        reverse_proxy 127.0.0.1:8081
      '';
      "office.archongrid.xyz".extraConfig = ''
        reverse_proxy 127.0.0.1:9980
      '';
    };
  };

  # Native Stuff
  # services.jellyfin = {
  #   enable = true;
  #   openFirewall = true;
  # };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;          # REQUIRED: pin major version explicitly
    hostName = "cloud.archongrid.xyz";
    https = true;                         # generate https URLs (TLS terminates at Caddy)

    datadir = "/data/nextcloud";          # user files on the HDD

    database.createLocally = true;        # provisions postgres + db + user
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/srv/nextcloud/admin-pass";   # file, not a string in the repo
    };

    # redis for locking/caching — the module wires php to it
    configureRedis = true;

    # php tuning — defaults are conservative
    maxUploadSize = "64G";
    phpOptions = {
      "opcache.interned_strings_buffer" = "32";
      "memory_limit" = lib.mkForce "1G";
    };
    poolSettings = {
      pm = "dynamic";
      "pm.max_children" = "120";
      "pm.start_servers" = "12";
      "pm.min_spare_servers" = "6";
      "pm.max_spare_servers" = "24";
    };

    # settings that land in config.php
    settings = {
      default_phone_region = "US";
      maintenance_window_start = 10;      # 2am pacific in UTC; background jobs window
      log_type = "file";
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };

    # declarative app management (optional but very set-and-forget)
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts calendar tasks notes;
      eurooffice = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/eurooffice/releases/download/v11.0.0/eurooffice-v11.0.0.tar.gz";
        sha256 = "sha256-Vsv5rtVXUchgXSSNbJVJ9Idfnvc9RaROuWxrG5L2/Ro=";        # leave empty, rebuild once, paste the hash from the error
        license = "agpl3Only";
      };
    };
    extraAppsEnable = true;
    appstoreEnable = false;               # apps come from the flake only; no drift
  };

  # the module sets up nginx on localhost; front it with Caddy
  services.nginx.virtualHosts."cloud.archongrid.xyz".listen = [
    { addr = "127.0.0.1"; port = 8081; }
  ];
  
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ "/data/nextcloud" ];
  
  systemd.tmpfiles.rules = [
    "d /data/nextcloud 0750 nextcloud nextcloud -"
    "d /srv/nextcloud  0750 root root -"
    "d /srv/eurooffice 0750 root root -"
  ];


  # Containerized Stuff
  
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {

      eurooffice = {
        image = "ghcr.io/euro-office/documentserver:9.3.2";
        environment = {
          JWT_ENABLED = "true";
        };
        environmentFiles = [ "/srv/eurooffice/secrets.env" ];
        volumes = [
          "/srv/eurooffice/data:/var/lib/euro-office/documentserver"
          "/srv/eurooffice/config:/etc/euro-office/documentserver"
          "/srv/eurooffice/logs:/var/log/euro-office/documentserver"
        ];
        ports = [ "127.0.0.1:9980:80" ];
      };

      # future containers go here as siblings: gluetun = { ... }; etc.
    };
  };
}