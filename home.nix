{ pkgs, ... }:

{
  home.username = "jsm";
  home.homeDirectory = "/home/jsm";
  home.stateVersion = "25.11";

  # Ghostty terminal
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMonoNL Nerd Font Mono";
    };
  };

  # User packages (moved from configuration.nix)
  home.packages = with pkgs; [
    kdePackages.kate
  ];
}
