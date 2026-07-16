{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
    
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;



}