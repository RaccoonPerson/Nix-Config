{ config, pkgs, lib, ... }:
{
  ## Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "cloud.archongrid.xyz";
    https = true;

    datadir = "/data/nextcloud";

    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/srv/nextcloud/admin-pass";
    };

    configureRedis = true;

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

    settings = {
      default_phone_region = "US";
      maintenance_window_start = 10; # 2am pacific
      log_type = "file";
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };

    # app management
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts calendar tasks notes;
      eurooffice = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/eurooffice/releases/download/v11.0.0/eurooffice-v11.0.0.tar.gz";
        sha256 = "sha256-Vsv5rtVXUchgXSSNbJVJ9Idfnvc9RaROuWxrG5L2/Ro=";
        license = "agpl3Only";
      };
    };
    extraAppsEnable = true;
    appstoreEnable = false;
  };

  # the module sets up nginx on localhost; front it with Caddy
  services.nginx.virtualHosts."cloud.archongrid.xyz".listen = [
    { addr = "127.0.0.1"; port = 8081; }
  ];
  
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ "/data/nextcloud" ];
  
  systemd.tmpfiles.rules = [
    "d /data/nextcloud        0750 nextcloud nextcloud -"
    "d /srv/nextcloud         0750 root root -"
    "d /srv/eurooffice        0750 root root -"
    "d /srv/eurooffice/data   0750 root root -"
    "d /srv/eurooffice/config 0750 root root -"
    "d /srv/eurooffice/logs   0750 root root -"
    "d /srv/eurooffice/data   0750 105 107 -"
  ];


  ## EuroOffice
  virtualisation.oci-containers.containers = {
    eurooffice = {
      image = "ghcr.io/euro-office/documentserver:v9.3.1@sha256:68a2659691ba233765e08eb4f8a0439992a8df213bb5c0999efb7db16c7b4c13";
      environment = {
        JWT_ENABLED = "true";
      };
      environmentFiles = [ "/srv/eurooffice/secrets.env" ];
      volumes = [
        "/srv/eurooffice/data:/var/lib/euro-office/documentserver"
      ];
      ports = [ "127.0.0.1:9980:80" ];
    };
  };

  ## Caddy
  services.caddy.virtualHosts = {
    "cloud.archongrid.xyz".extraConfig = ''
      reverse_proxy 127.0.0.1:8081
      '';
    "office.archongrid.xyz".extraConfig = ''
      reverse_proxy 127.0.0.1:9980
    '';
  };

}