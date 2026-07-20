{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
    
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TEMP while waiting for certs
  # services.caddy.globalConfig = ''
  #   local_certs
  # '';

}