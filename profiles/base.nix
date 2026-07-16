{ config, lib, pkgs, inputs, ... }:

{
  imports = [  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
    };
  };

  networking.firewall.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = lib.mkDefault 50;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    ripgrep
    fd
    tree
    curl
    wget
    rsync
    smartmontools
    pciutils
    usbutils
  ];

  services.journald.extraConfig = "SystemMaxUse=500M";

  system.stateVersion = lib.mkDefault "26.05";
}