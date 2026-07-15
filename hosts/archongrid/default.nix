{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
    ../../users/vro
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mine.jellyfin.enable = true;

}