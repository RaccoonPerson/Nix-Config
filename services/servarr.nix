# servarr.nix — media management stack (replaces docker-compose.mediastack.yml)
#
# Native NixOS modules for sonarr/radarr/prowlarr/bazarr/flaresolverr,
# rootful podman for jellyseerr (the native module's configDir option is
# broken when relocated — nixpkgs#457739 — so a container gives us
# /srv/servarr/jellyseerr cleanly).
#
# Requires nixpkgs 25.11+; prowlarr.dataDir needs 26.05/unstable
# (the option was silently ignored on 25.11 — nixpkgs#445983).
#
# Not expressible in nix: root folders, download clients, quality profiles.
# Those live in each app's SQLite DB — set them in the UI:
#   Sonarr  root folder:  /data/media/tv
#   Radarr  root folder:  /data/media/movies
#   Download client paths: /scratch/downloads/{torrents,usenet}/...
# (Recyclarr / Buildarr exist if you ever want that layer declarative too.)

{ config, lib, pkgs, ... }:

{
  #### Shared group + directory layout ########################################

  # gid 1100 matches the PUID/PGID from the compose stack, so any files the
  # docker containers created keep their group without a re-chown.
  users.groups.media.gid = 1100;

  # setgid (2xxx) so everything created inside inherits group `media`.
  systemd.tmpfiles.rules = [
    "d /data                                      0755 root root  -"
    "d /data/media                                2775 root media -"
    "d /data/media/movies                         2775 root media -"
    "d /data/media/tv                             2775 root media -"

    "d /scratch/downloads                         2775 root media -"
    "d /scratch/downloads/torrents                2775 root media -"
    "d /scratch/downloads/torrents/movies         2775 root media -"
    "d /scratch/downloads/torrents/tv             2775 root media -"
    "d /scratch/downloads/usenet                  2775 root media -"
    "d /scratch/downloads/usenet/complete         2775 root media -"
    "d /scratch/downloads/usenet/complete/movies  2775 root media -"
    "d /scratch/downloads/usenet/complete/tv      2775 root media -"
    "d /scratch/downloads/usenet/incomplete       2775 root media -"

    # sonarr/radarr do NOT create non-default dataDirs themselves;
    # bazarr and prowlarr modules handle their own.
    "d /srv/servarr             0755 root   root  -"
    "d /srv/servarr/sonarr      0700 sonarr media -"
    "d /srv/servarr/radarr      0700 radarr media -"
    "d /srv/servarr/jellyseerr  0755 root   root  -"
  ];

  #### *arr services ###########################################################
  # `settings` maps to SONARR__SECTION__KEY env vars — config.xml-level only
  # (port, urlbase, auth, postgres). Ports below are the defaults, pinned here
  # because openFirewall reads them. Secrets (API keys) go in environmentFiles.

  services.sonarr = {
    enable = true;
    dataDir = "/srv/servarr/sonarr";
    group = "media";
    openFirewall = true; # drop these once everything is fronted by Caddy
    settings.server.port = 8989;
  };

  services.radarr = {
    enable = true;
    dataDir = "/srv/servarr/radarr";
    group = "media";
    openFirewall = true;
    settings.server.port = 7878;
  };

  services.prowlarr = {
    enable = true;
    # Module bind-mounts this over /var/lib/private/prowlarr (DynamicUser).
    # Doesn't touch media files, so no group needed.
    dataDir = "/srv/servarr/prowlarr";
    openFirewall = true;
    settings.server.port = 9696;
  };

  services.bazarr = {
    enable = true;
    dataDir = "/srv/servarr/bazarr"; # module creates this itself
    group = "media";
    openFirewall = true;
  };

  services.flaresolverr = {
    enable = true;
    port = 8191;
    # openFirewall omitted on purpose: only prowlarr talks to it, same host.
  };

  # The *arr units ship with UMask=0022, which makes imported files 644/755 —
  # group `media` then can't write, and bazarr fails saving subtitles next to
  # the media. 0002 + the setgid dirs above = 664/775, group media.
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

  #### Jellyseerr (podman) #####################################################
  # PUID/PGID from the compose file dropped — that's a linuxserver.io
  # convention the fallenbagel image ignores. TZ kept: containers don't
  # inherit the host time.timeZone.

  virtualisation.podman.enable = true;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.jellyseerr = {
      image = "docker.io/fallenbagel/jellyseerr:2.7.3"; # bump
      autoStart = true;
      ports = [ "5055:5055" ];
      volumes = [ "/srv/servarr/jellyseerr:/app/config" ];
      environment = {
        TZ = "America/Los_Angeles";
        LOG_LEVEL = "info";
      };
    };
  };

  # podmans published ports usually punch through anyway
  networking.firewall.allowedTCPPorts = [ 5055 ];
}
