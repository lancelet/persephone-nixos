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

  # Zsh
  programs.zsh = {
    enable = true;
    shellAliases = {
      nrs = "pushd -q ~/persephone-nixos && sudo nixos-rebuild switch --flake .#persephone ; popd -q";
    };
  };

  # Starship prompt (Omarchy-style minimal)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 200;
      format = "[$directory$git_branch$git_status]($style)$character";
      character = {
        error_symbol = "[✗](bold cyan)";
        success_symbol = "[❯](bold cyan)";
      };
      directory = {
        truncation_length = 2;
        truncation_symbol = "…/";
        repo_root_style = "bold cyan";
        repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };
      git_branch = {
        format = "[$branch]($style) ";
        style = "italic cyan";
      };
      git_status = {
        format = "[$all_status]($style)";
        style = "cyan";
        ahead = "⇡\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        behind = "⇣\${count} ";
        conflicted = " ";
        up_to_date = " ";
        untracked = "? ";
        modified = " ";
        stashed = "";
        staged = "";
        renamed = "";
        deleted = "";
      };
    };
  };

  # Atuin - shell history
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  # User packages (moved from configuration.nix)
  home.packages = with pkgs; [
    kdePackages.kate
  ];
}
