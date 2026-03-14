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
      nrs = "pushd -q ~/persephone-nixos && sudo nixos-rebuild switch --flake .#$(hostname) ; popd -q";
      nrsf = "pushd -q ~/persephone-nixos && sudo nixos-rebuild switch --fast --flake .#$(hostname) ; popd -q";
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
  programs.noctalia-shell.enable = true;

  # Niri — bindings from niri's default-config.kdl, with ghostty substituted for alacritty.
  # Stylix handles focus-ring/border colours and cursor automatically.
  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    input = {
      keyboard = {
        xkb.layout = "us";
        numlock = true;
      };
      touchpad = {
        tap = false;
        natural-scroll = true;
      };
    };

    layout = {
      gaps = 16;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width = {
        proportion = 0.5;
      };
    };

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

      "Mod+T".action.spawn = "ghostty";
      "Mod+D".action.spawn = "fuzzel";
      "Super+Alt+L".action.spawn = "swaylock";

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "+10%"
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "10%-"
        ];
      };

      "Mod+O" = {
        repeat = false;
        action.toggle-overview = [ ];
      };
      "Mod+Q" = {
        repeat = false;
        action.close-window = [ ];
      };

      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Down".action.focus-window-down = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];
      "Mod+L".action.focus-column-right = [ ];

      "Mod+Ctrl+Left".action.move-column-left = [ ];
      "Mod+Ctrl+Down".action.move-window-down = [ ];
      "Mod+Ctrl+Up".action.move-window-up = [ ];
      "Mod+Ctrl+Right".action.move-column-right = [ ];
      "Mod+Ctrl+H".action.move-column-left = [ ];
      "Mod+Ctrl+J".action.move-window-down = [ ];
      "Mod+Ctrl+K".action.move-window-up = [ ];
      "Mod+Ctrl+L".action.move-column-right = [ ];

      "Mod+Home".action.focus-column-first = [ ];
      "Mod+End".action.focus-column-last = [ ];
      "Mod+Ctrl+Home".action.move-column-to-first = [ ];
      "Mod+Ctrl+End".action.move-column-to-last = [ ];

      "Mod+Shift+Left".action.focus-monitor-left = [ ];
      "Mod+Shift+Down".action.focus-monitor-down = [ ];
      "Mod+Shift+Up".action.focus-monitor-up = [ ];
      "Mod+Shift+Right".action.focus-monitor-right = [ ];
      "Mod+Shift+H".action.focus-monitor-left = [ ];
      "Mod+Shift+J".action.focus-monitor-down = [ ];
      "Mod+Shift+K".action.focus-monitor-up = [ ];
      "Mod+Shift+L".action.focus-monitor-right = [ ];

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

      "Mod+Page_Down".action.focus-workspace-down = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+U".action.focus-workspace-down = [ ];
      "Mod+I".action.focus-workspace-up = [ ];
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];
      "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];
      "Mod+Shift+Page_Down".action.move-workspace-down = [ ];
      "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
      "Mod+Shift+U".action.move-workspace-down = [ ];
      "Mod+Shift+I".action.move-workspace-up = [ ];

      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = [ ];
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = [ ];
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = [ ];
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = [ ];
      };
      "Mod+WheelScrollRight".action.focus-column-right = [ ];
      "Mod+WheelScrollLeft".action.focus-column-left = [ ];
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];
      "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
      "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
      "Mod+Comma".action.consume-window-into-column = [ ];
      "Mod+Period".action.expel-window-from-column = [ ];

      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+Shift+R".action.switch-preset-window-height = [ ];
      "Mod+Ctrl+R".action.reset-window-height = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];
      "Mod+C".action.center-column = [ ];
      "Mod+Ctrl+C".action.center-visible-columns = [ ];
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+V".action.toggle-window-floating = [ ];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];
      "Mod+W".action.toggle-column-tabbed-display = [ ];

      "Print".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];

      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = [ ];
      };
      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];
      "Mod+Shift+P".action.power-off-monitors = [ ];
    };

    layer-rules = [
      # Noctalia overview wallpaper
      {
        matches = [ { namespace = "^noctalia-overview.*"; } ];
        place-within-backdrop = true;
      }
    ];

    # Force AMD render node; niri's heuristic picks NVIDIA's renderD129 which fails
    # on the RTX 5070 (unsupported GPU). eDP-1 is on AMD in reverseSync mode anyway,
    # so this is also the more efficient path (no cross-GPU copy needed).
    debug."render-drm-device" = "/dev/dri/by-path/pci-0000:c3:00.0-render";
  };

  # KDE Plasma replaces HM's .gtkrc-2.0 symlink with a regular file on every login;
  # force-overwrite it so Stylix theming isn't blocked (home-manager#6188)
  gtk.gtk2.force = true;

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
    kdePackages.kate
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
