{ config, lib, pkgs, ... }:
{
  imports = [
    ./base.nix
    ../services/tailscale.nix
    ../services/adguardhome.nix
    ../services/nextcloud.nix
    ../services/jellyfin.nix
    ../services/servarr.nix
    ../services/downloaders.nix
    ];

  # Disable HTML Docs while leaving man intact
  documentation.nixos.enable = false;
  documentation.man.enable = true;
  documentation.doc.enable = false;
  environment.defaultPackages = lib.mkForce [ 
    pkgs.dig 
  ];

  ## Networking
  networking.useNetworkd = true;
  networking.useDHCP = false;
  networking.hosts."192.168.1.217" = [ "arhchongrid.xyz" "auth.archongrid.xyz" "cloud.archongrid.xyz" "jellyfin.archongrid.xyz" "adguard.archongrid.xyz" ];
  systemd.network = {
  enable = true;
  networks."10-lan" = {
    matchConfig.Name = "enp*";
    address = [ "192.168.1.217/24" ];
    gateway = [ "192.168.1.1" ];
    dns = [ "127.0.0.1" ];
  };
};

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