{ config, lib, pkgs, ... }:
{
  imports = [ ./base.nix ];

  documentation.nixos.enable = false;
  documentation.man.enable = true;
  documentation.doc.enable = false;
  environment.defaultPackages = lib.mkForce [ 
    pkgs.dig 
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "no";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";

  services.caddy.enable = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  boot.tmp.cleanOnBoot = true;

  users.mutableUsers = false;

  users.users.vro = {
    isNormalUser = true;
    description = "Vro";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKgl6tQV9fnfRgzKxqn8tMMT3SooLWEhf6N2X3BFGz3" 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJzqsEI3+A7HV9WxIhLiZUeSeTHLa9WKg7WLcGRpAt6g"
    ];
  };
  # for remote deployment :P
  security.sudo.wheelNeedsPassword = false;
}