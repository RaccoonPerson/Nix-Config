{ config, pkgs, lib, ... }:
{
  # imports = [ ./default.nix ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nixd
    nixfmt-rfc-style
    statix
    nix-output-monitor  # nom build
    nvd           
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      archongrid = {
        hostname = "10.0.0.2";
        user = "racc";
      };
      vps = {
        hostname = "203.0.113.7";
        user = "racc";
        port = 22;
      };
    };
  };

  home.shellAliases = {
    deploy-grid = "nixos-rebuild switch --flake ~/src/Server-Nix-Config#archongrid --target-host archongrid --use-remote-sudo";
    deploy-vps  = "nixos-rebuild switch --flake ~/src/Server-Nix-Config#vps --target-host vps --use-remote-sudo";
    hm          = "home-manager switch --flake ~/src/Server-Nix-Config#racc@fedora";
  };
}