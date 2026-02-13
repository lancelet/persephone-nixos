{ config, pkgs, lib, ... }:

let
  theme = import ./theme.nix;
  current = theme.${theme.active};
in
{
  imports = [ ./neovim.nix ];

  home.username = "jsm";
  home.homeDirectory = "/home/jsm";
  home.stateVersion = "25.11";

  # KDE Plasma settings (via plasma-manager)
  programs.plasma.enable = true;
  programs.plasma.overrideConfig = true;
  programs.plasma.input.touchpads = [
    {
      name = "PIXA3854:00 093A:0274 Touchpad";
      vendorId = "093a";
      productId = "0274";
      rightClickMethod = "twoFingers";
      tapToClick = false;
      naturalScroll = true;
      scrollSpeed = 0.5;
    }
  ];

  # Bottom panel — auto-hide like macOS dock
  programs.plasma.panels = [
    {
      location = "bottom";
      hiding = "autohide";
      floating = true;
      screen = "all";
      widgets = [
        "org.kde.plasma.kickoff"
        "org.kde.plasma.pager"
        "org.kde.plasma.icontasks"
        "org.kde.plasma.marginsseparator"
        "org.kde.plasma.systemtray"
        "org.kde.plasma.digitalclock"
        "org.kde.plasma.showdesktop"
      ];
    }
  ];

  # Ghostty terminal
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMonoNL Nerd Font Mono";
      keybind = [
        "ctrl+shift+n=new_window"
        "ctrl+n=new_window"
      ];
    };
  };

  # Zsh
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = {
      nrs = "pushd -q ~/persephone-nixos && sudo nixos-rebuild switch --flake .#persephone ; popd -q";
      nrsf = "pushd -q ~/persephone-nixos && sudo nixos-rebuild switch --fast --flake .#persephone ; popd -q";
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
        format = "[$all_status$ahead_behind]($style)";
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

  # Git
  programs.git = {
    enable = true;
    settings.user = {
      name = "Jonathan Merritt";
      email = "j.s.merritt@gmail.com";
    };
  };

  # Atuin - shell history
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
  };

  # VS Code
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        anthropic.claude-code
        jnoortheen.nix-ide
        leanprover.lean4
        tamasfe.even-better-toml
        haskell.haskell
        justusadam.language-haskell
        james-yu.latex-workshop
        asvetliakov.vscode-neovim
      ]) ++ lib.optional (current ? vscode)
        (pkgs.vscode-utils.extensionFromVscodeMarketplace current.vscode.extension);
      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [ 80 120 ];
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
      } // lib.optionalAttrs (current ? vscode) {
        "workbench.colorTheme" = lib.mkForce current.vscode.themeName;
      };
    };
  };

  # KDE Plasma replaces HM's .gtkrc-2.0 symlink with a regular file on every login;
  # force-overwrite it so Stylix theming isn't blocked (home-manager#6188)
  gtk.gtk2.force = true;

  # Ensure nvim data directory exists (neo-tree needs it for logging on first launch)
  xdg.enable = true;
  home.file.".local/share/nvim/.keep".text = "";

  # User packages
  home.packages = with pkgs; [
    kdePackages.kate
    brave
    gh
    jq
    tree
    ripgrep
    fd
    bat
    btop

    # Lean
    elan

    # Haskell
    ghc
    cabal-install
    haskell-language-server

    # LaTeX
    texlive.combined.scheme-full
  ];
}
