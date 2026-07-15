{ config, lib, pkgs, ... }:

let
  cfg = config.mine.jellyfin;
in
{
  options.mine.jellyfin = {
    enable = lib.mkEnableOption "jellyfin, wired into caddy + storage";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "jellyfin.example.com";
      description = "Caddy vhost; null = no reverse proxy entry";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/data/media";
    };

    hwAccel = lib.mkOption {
      type = lib.types.enum [ "none" "intel" "nvidia" ];
      default = "none";
      description = "QSV/VAAPI on the N100, nvenc if it lands on the 3070 box";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = false;   # LAN access goes through caddy; flip if you want :8096 direct
    };

    users.users.jellyfin.extraGroups =
      lib.mkIf (cfg.hwAccel != "none") [ "render" "video" ];

    hardware.graphics = lib.mkIf (cfg.hwAccel == "intel") {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 jellyfin media -"
    ];
    users.groups.media = { };

    services.caddy.virtualHosts = lib.mkIf (cfg.domain != null) {
      ${cfg.domain}.extraConfig = ''
        reverse_proxy localhost:8096
      '';
    };
  };
}