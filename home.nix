{
  config,
  pkgs,
  lib,
  ...
}:

let
  theme = import ./theme.nix;
  current = theme.${theme.active};
in
{
  imports = [
    ./neovim.nix
    ./niri.nix
  ];

  home.username = "jsm";
  home.homeDirectory = "/home/jsm";
  home.stateVersion = "25.11";

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
      nrs = "pushd -q ~/persephone-nixos && nix fmt $(find . -name '*.nix') && sudo nixos-rebuild switch --flake .#$(hostname) ; popd -q";
      nrsf = "pushd -q ~/persephone-nixos && nix fmt $(find . -name '*.nix') && sudo nixos-rebuild switch --fast --flake .#$(hostname) ; popd -q";
      nrf = "pushd -q ~/persephone-nixos && nix fmt $(find . -name '*.nix') ; popd -q";
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

  # Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    # Use the largest attached client's dimensions so resizing one Ghostty
    # window doesn't constrain other windows sharing the same session.
    extraConfig = "set -g window-size largest";
  };

  # VS Code
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions =
        (with pkgs.vscode-extensions; [
          anthropic.claude-code
          jnoortheen.nix-ide
          leanprover.lean4
          tamasfe.even-better-toml
          haskell.haskell
          justusadam.language-haskell
          james-yu.latex-workshop
          asvetliakov.vscode-neovim
        ])
        ++ lib.optional (current ? vscode) (
          pkgs.vscode-utils.extensionFromVscodeMarketplace current.vscode.extension
        );
      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [
          80
          120
        ];
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
      }
      // lib.optionalAttrs (current ? vscode) {
        "workbench.colorTheme" = lib.mkForce current.vscode.themeName;
      };
    };
  };

  # Noctalia shell (Quickshell-based panel, notifications, launcher, control centre)
  programs.noctalia-shell = {
    enable = true;
    settings = {
      location.name = "Sydney";
      bar.widgets.right = [
        { id = "Tray"; }
        { id = "NotificationHistory"; }
        { id = "Battery"; }
        { id = "Volume"; }
        { id = "Brightness"; }
        { id = "PowerProfile"; }
        { id = "ControlCenter"; }
      ];
    };
  };

  # Icon theme
  gtk.iconTheme = {
    package = pkgs.papirus-icon-theme;
    name = "Papirus-Dark";
  };

  # Ensure nvim data directory exists (neo-tree needs it for logging on first launch)
  xdg.enable = true;
  home.file.".local/share/nvim/.keep".text = "";

  # Brave browser with extensions
  programs.brave = {
    enable = true;
    extensions = [
      { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1Password
    ];
  };

  # User packages
  home.packages = with pkgs; [
    fuzzel
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
