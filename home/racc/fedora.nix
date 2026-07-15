{ config, pkgs, lib, ... }:
{
  # imports = [ ./default.nix ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nixd
    nixfmt-rfc-style
    statix      # lint / dead-code
    nix-output-monitor  # `nom build` — readable build output
    nvd                 # diff two system generations
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;   # cached, doesn't re-eval on every cd
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      archongrid = {
        hostname = "10.0.0.2";       # wg ip
        user = "racc";
      };
      vps = {
        hostname = "203.0.113.7";
        user = "racc";
        port = 22;                   # or your moved port
      };
    };
  };

  home.shellAliases = {
    deploy-grid = "nixos-rebuild switch --flake ~/src/Server-Nix-Config#archongrid --target-host archongrid --use-remote-sudo";
    deploy-vps  = "nixos-rebuild switch --flake ~/src/Server-Nix-Config#vps --target-host vps --use-remote-sudo";
    hm          = "home-manager switch --flake ~/src/Server-Nix-Config#racc@fedora";
  };
}