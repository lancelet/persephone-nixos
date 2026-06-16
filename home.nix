# Home Manager configuration for jsm.
#
# Minimal by design. Add user packages to home.packages, program modules as
# `programs.<name>`, and declarative KDE settings under `programs.plasma`.

{
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.zen-browser.homeModules.beta ];

  home.username = "jsm";
  home.homeDirectory = "/home/jsm";
  home.stateVersion = "25.11";

  programs.zsh = {
    enable = true;
    shellAliases = {
      # Build the current host's config without activating it.
      nrb = "nixos-rebuild build --flake ~/persephone-nixos#$(hostname)";
      # Format the flake, then build and switch.
      nrs = "nix fmt ~/persephone-nixos && sudo nixos-rebuild switch --flake ~/persephone-nixos#$(hostname)";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Jonathan Merritt";
        email = "j.s.merritt@gmail.com";
      };
      # Use Neovim for commit messages, interactive rebase, etc.
      core.editor = "nvim";
    };
  };

  # Neovim, set as the default editor ($EDITOR=nvim), with vi/vim aliases.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Atuin: magical shell history (Ctrl-R search, etc.). Zsh integration is
  # enabled by default.
  programs.atuin.enable = true;

  # Starship prompt, configured as the official "Pure preset" — a clean,
  # minimal two-line prompt emulating sindresorhus/pure. Zsh integration is on
  # by default (injected into the HM-managed zshrc above). No Nerd Font needed:
  # the only glyphs are plain Unicode (❯/❮). Settings below are the Pure preset
  # (https://starship.rs/presets/pure-preset) translated to Nix.
  programs.starship = {
    enable = true;
    settings =
      # The Pure preset marks "dirty" git state with a single `*`, using a
      # zero-width space as each per-category symbol so the group renders the
      # `*` without printing per-category letters. fromJSON decodes the
      # \u200b escape, so no invisible character is pasted into this file.
      let
        zwsp = builtins.fromJSON ''"\u200b"'';
      in
      {
        format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$python$character";

        directory.style = "blue";

        character = {
          success_symbol = "[❯](purple)";
          error_symbol = "[❯](red)";
          vimcmd_symbol = "[❮](green)";
        };

        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };

        git_status = {
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
          style = "cyan";
          conflicted = zwsp;
          untracked = zwsp;
          modified = zwsp;
          staged = zwsp;
          renamed = zwsp;
          deleted = zwsp;
          stashed = "≡";
        };

        git_state = {
          format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
          style = "bright-black";
        };

        cmd_duration = {
          format = "[$duration]($style) ";
          style = "yellow";
        };

        python = {
          format = "[$virtualenv]($style) ";
          style = "bright-black";
          detect_extensions = [ ];
          detect_files = [ ];
        };
      };
  };

  # direnv: per-directory environments loaded automatically on `cd`. nix-direnv
  # provides the `use flake` stdlib function and caches the dev shell so it
  # doesn't re-evaluate on every entry. Zsh integration is on by default, so a
  # project `.envrc` containing `use flake` activates that flake's dev shell
  # once `direnv allow` has been run there.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Declarative KDE Plasma configuration.
  # See https://nix-community.github.io/plasma-manager/
  programs.plasma = {
    enable = true;
    # Catppuccin Mocha (Mauve accent) colour scheme. The scheme file ships in the
    # catppuccin-kde package (home.packages below); "CatppuccinMochaMauve" is the
    # basename of its .colors file. We keep the breezedark look-and-feel (dark
    # Plasma theme + window decorations) and only override the colours, rather
    # than applying Catppuccin's full global theme — staying close to stock per
    # the desktop direction. Owning this here also overwrites any orphaned prior
    # theming.
    #
    # widgetStyle = "kvantum" swaps the Qt *application style* from Breeze to
    # Kvantum (engine + Catppuccin Mocha/Mauve Kvantum theme in home.packages
    # below; the theme is selected by ~/.config/Kvantum/kvantum.kvconfig further
    # down). The sole motivation is scrollbars: stock Breeze hardcodes a track +
    # handle with no knob to slim it down, whereas the Catppuccin Kvantum theme
    # ships transient (overlay) scrollbars — no groove, just a thin handle that
    # fades in on hover. Kvantum's widgets otherwise track the same Mocha/Mauve
    # palette, so the desktop stays cohesive.
    workspace = {
      colorScheme = "CatppuccinMochaMauve";
      lookAndFeel = "org.kde.breezedark.desktop";
      widgetStyle = "kvantum";
    };
    # Mouse tuning. IDs are hex (plasma-manager converts to the decimal KDE
    # stores); "default" is the adaptive acceleration profile.
    input.mice = [
      {
        name = "Logitech G502";
        vendorId = "046d";
        productId = "407f";
        acceleration = -0.8;
        accelerationProfile = "default";
        naturalScroll = true;
      }
    ];
    # macOS Spotlight-style launcher: Meta+Space opens KRunner (kept alongside
    # the default Alt+Space). FreeFloating makes KRunner a centred floating box
    # rather than docking to the top edge of the screen.
    shortcuts."org.kde.krunner.desktop"."_launch" = [
      "Alt+Space"
      "Meta+Space"
    ];
    configFile.krunnerrc.General.FreeFloating = true;
  };

  # Select the Kvantum theme (the engine reads this file on startup). Pointing it
  # at the Catppuccin Mocha/Mauve theme is what actually activates the subtle
  # overlay scrollbars described in the workspace block above — the theme's own
  # kvconfig carries transient_scrollbar=true and transient_groove=false, so
  # nothing else needs setting here.
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-mauve
  '';

  # Konsole: a declarative profile using the same JetBrainsMono Nerd Font coding
  # font as VSCodium (nerd-fonts.jetbrains-mono in home.packages). The "Mono"
  # family variant keeps icon glyphs single-width so terminal columns stay
  # aligned. Konsole's built-in default profile can't be edited in place, so we
  # own a named profile and default to it.
  programs.konsole = {
    enable = true;
    defaultProfile = "JetBrains";
    profiles.JetBrains = {
      name = "JetBrains";
      font = {
        name = "JetBrainsMono Nerd Font Mono";
        size = 11;
      };
    };
  };

  # VSCodium with extensions managed declaratively. Uses the dedicated
  # programs.vscodium module so config lands in VSCodium's own paths
  # (programs.vscode now always writes to upstream VS Code's paths).
  programs.vscodium = {
    enable = true;
    # Let home-manager own extensions/extensions.json (the manifest VSCodium uses
    # to decide which extensions to activate). Left mutable (the default),
    # VSCodium rewrites it and it drifts out of sync with the declaratively
    # symlinked extension folders — which silently dropped nix-ide and killed
    # Nix syntax highlighting. Immutable keeps the manifest == the list below.
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim # Vim keybindings
        jnoortheen.nix-ide # Nix syntax highlighting + LSP
        leanprover.lean4 # Lean 4 language support
        tamasfe.even-better-toml # required dependency of lean4 (not auto-installed for Nix-managed extensions)
        mkhl.direnv # feed direnv/flake dev-shell env (cc, toolchain) to the Lean server
        catppuccin.catppuccin-vsc # Catppuccin colour themes (Mocha/Latte/Frappé/Macchiato)
        stkb.rewrap # Alt+Q hard-wraps the paragraph/selection at the ruler column
      ];
      userSettings = {
        # Drive nix-ide's language features with nil (provided below).
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        # Reload the direnv environment automatically when .envrc/flake change,
        # so the Lean 4 server always sees the project's dev shell.
        "direnv.restart.automatic" = true;
        # Dispatch keys by OS-translated keyCode rather than physical key
        # position, so the system caps:escape remap (common.nix) reaches the
        # editor — required for CapsLock-as-Esc to work with Vim mode.
        "keyboard.dispatch" = "keyCode";
        # Route Vim's unnamed register to the system clipboard, so a plain
        # `y` yank (and `d`/`x` deletes) copies out and `p` pastes from it.
        "vim.useSystemClipboard" = true;

        # Appearance and editing.
        "workbench.colorTheme" = "Catppuccin Mocha";
        "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', monospace"; # coding font (pkg below)
        "editor.fontLigatures" = true; # JetBrains Mono's programming ligatures (->, =>, ==)
        "editor.minimap.enabled" = false; # no code-preview strip on the right
        "editor.wordWrap" = "bounded"; # soft-wrap long lines …
        "editor.wordWrapColumn" = 100; # … at column 100 (or the window edge)
        "editor.rulers" = [ 100 ]; # vertical guide at the wrap column
      };
    };
  };

  # Zen browser (module imported above). Native-Wayland; pairs with the
  # system-level 1Password browser trust configured in common.nix.
  programs.zen-browser.enable = true;

  # Let home-manager manage a user fontconfig so fonts in home.packages (below)
  # are discoverable by apps like VSCodium.
  fonts.fontconfig.enable = true;

  # User packages.
  home.packages = with pkgs; [
    nil # Nix language server (used by nix-ide above)
    elan # Lean toolchain manager (used by the Lean 4 extension)
    google-chrome # 1Password-trusted by default; native Wayland via NIXOS_OZONE_WL
    nerd-fonts.jetbrains-mono # coding font w/ Nerd Font glyphs (VSCodium + Konsole)
    # Catppuccin KDE colour scheme. Installs share/color-schemes/Catppuccin*.colors
    # (referenced by programs.plasma.workspace.colorScheme above). Built for just
    # Mocha/Mauve to keep the closure small; add more flavours/accents here to
    # make them selectable in System Settings.
    (catppuccin-kde.override {
      flavour = [ "mocha" ];
      accents = [ "mauve" ];
      winDecStyles = [ "modern" ];
    })
    # Kvantum SVG theme engine (the Qt6 style plugin that backs
    # programs.plasma.workspace.widgetStyle = "kvantum" above). Ships
    # lib/qt-6/plugins/styles/libkvantum.so; the Plasma session finds it because
    # NixOS's QT_PLUGIN_PATH is profile-relative and useUserPackages installs
    # this into the per-user profile — so no system-level change is needed.
    kdePackages.qtstyleplugin-kvantum
    # Catppuccin Mocha (Mauve) Kvantum theme. Installs
    # share/Kvantum/catppuccin-mocha-mauve/, which kvantum.kvconfig (above)
    # selects. Ships transient (overlay) scrollbars — the whole point of the
    # switch. Built for just Mocha/Mauve to match the colour scheme.
    (catppuccin-kvantum.override {
      variant = "mocha";
      accent = "mauve";
    })
  ];
}
