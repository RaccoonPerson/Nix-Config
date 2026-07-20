{ config, pkgs, ... }:
{
  ## Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = false; # LAN access goes through Caddy
  };

  users.groups.media = { };
  users.users.jellyfin.extraGroups = [ "media" ];
  systemd.tmpfiles.rules = [
    "d /data/media 0775 jellyfin media -"
  ];

  ## Caddy
  services.caddy.virtualHosts."jellyfin.archongrid.xyz".extraConfig = ''
    reverse_proxy 127.0.0.1:8096
  '';
}
