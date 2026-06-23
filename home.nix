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
      # vi/vim → nvim (replaces programs.neovim's viAlias/vimAlias, which we dropped
      # so home-manager doesn't manage ~/.config/nvim — see the neovim note below).
      vi = "nvim";
      vim = "nvim";
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

  # Neovim is installed as a plain package (see home.packages) rather than via
  # programs.neovim. That module generates and OWNS ~/.config/nvim/init.lua, which
  # clobbers a hand-installed LazyVim (whose entry point is that same init.lua). By
  # installing only the binary we leave ~/.config/nvim entirely to LazyVim. The
  # module's conveniences are replicated by hand: $EDITOR here, vi/vim aliases in
  # programs.zsh.shellAliases above.
  home.sessionVariables.EDITOR = "nvim";

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
    # Plasma theme) and only override the colours, rather than applying
    # Catppuccin's full global theme — staying close to stock per the desktop
    # direction. Owning this here also overwrites any orphaned prior theming.
    #
    # windowDecorations swaps the title bars from Breeze to Klassy (binary
    # KDecoration plugin in home.packages below; library "org.kde.klassy", theme
    # "Klassy"). This is purely the *decoration* — title bar, borders, and
    # close/min/max buttons — so it's orthogonal to widgetStyle: scrollbars and
    # other widget internals stay with Kvantum. Klassy also ships an application
    # *style* (klassy6.so), but we deliberately do NOT select it via widgetStyle,
    # which would clobber the Kvantum overlay scrollbars below.
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
      windowDecorations = {
        library = "org.kde.klassy";
        theme = "Klassy";
      };
      # Desktop wallpaper: a Catppuccin-Mocha-recoloured astronaut scene from
      # orangci's wallpaper repo (palette-matched to the Mauve accent). Fetched
      # into the Nix store by hash so it's reproducible — no loose file to lose,
      # and the build fails loudly if the upstream image ever changes. Swap by
      # editing the url + hash (get the new hash from `nix store prefetch-file`).
      wallpaper = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/astronaut.png";
        hash = "sha256-fsE/tDzlt1gP7mu3ueJU7IDhxOZRDYDVezHviBkzKlk=";
      };
    };

    # Power management: have KDE (PowerDevil) auto-switch power-profiles-daemon
    # profiles by power source — full Performance on AC, Power Saver on battery
    # (and on low battery). This is the AC-vs-battery split; the dGPU's RTD3
    # power-off (hosts/persephone) does the heavy lifting for unplugged runtime.
    # dimDisplay on battery is a safe extra saver. (No-op on a desktop like
    # hercules, which has no battery.) "powerSaving" maps to PPD's power-saver.
    powerdevil = {
      AC.powerProfile = "performance";
      battery = {
        powerProfile = "powerSaving";
        dimDisplay.enable = true;
      };
      lowBattery.powerProfile = "powerSaving";
    };
    # Mouse tuning. The G502 enumerates as TWO different devices and KDE stores
    # per-device settings, so both must be declared or whichever mode isn't
    # configured falls back to KDE defaults — the cause of the "jerky when I plug
    # it in to charge" inconsistency:
    #   - wired / charging:  "Logitech G502"                              (407f)
    #   - wireless Lightspeed: "Logitech G502 LIGHTSPEED Wireless Gaming Mouse" (c08d)
    # IDs are hex (plasma-manager converts to the decimal KDE stores). Acceleration
    # profile: "default" = KDE's adaptive (speed-dependent) curve; "none" = flat /
    # 1:1 with no acceleration. If the pointer still feels jerky in both modes,
    # switch both to "none" — the adaptive curve is the usual culprit.
    input.mice =
      let
        g502 = {
          acceleration = 0.0; # KDE "pointer speed" slider (PointerAcceleration); 0 = middle
          accelerationProfile = "default";
          naturalScroll = true;
          scrollSpeed = 5; # KDE "scroll speed" slider (ScrollFactor); raised to offset hi-res off
        };
      in
      [
        (
          g502
          // {
            name = "Logitech G502";
            vendorId = "046d";
            productId = "407f";
          }
        )
        (
          g502
          // {
            name = "Logitech G502 LIGHTSPEED Wireless Gaming Mouse";
            vendorId = "046d";
            productId = "c08d";
          }
        )
      ];
    # macOS Spotlight-style launcher: Meta+Space opens KRunner (kept alongside
    # the default Alt+Space). FreeFloating makes KRunner a centred floating box
    # rather than docking to the top edge of the screen.
    shortcuts."org.kde.krunner.desktop"."_launch" = [
      "Alt+Space"
      "Meta+Space"
    ];
    configFile.krunnerrc.General.FreeFloating = true;
    # Bottom panel, reproduced from the stock Plasma 6 layout so we can set it to
    # auto-hide (macOS-dock style): it slides off-screen and reappears when the
    # cursor hits the bottom edge. Declaring a panel here makes plasma-manager
    # *own* it, replacing the live one — so the widget list below must mirror the
    # default panel exactly (order taken from the running AppletOrder). Bare
    # widget strings inherit each plasmoid's defaults, matching the unconfigured
    # applets we replaced; the system tray auto-populates the standard items.
    panels = [
      {
        location = "bottom";
        hiding = "autohide";
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

  # Klassy window-decoration settings, baked from the GUI config (Klassy KCM →
  # Configure). The "Klassy" theme selected in programs.plasma.workspace.
  # windowDecorations reads this on startup; without it Klassy falls back to its
  # built-in defaults. Tuned look: small-circle traffic-light buttons (accent
  # colours, Oxygen icons), 6px window-corner radius, 8px side / 6px top-bottom
  # title-bar margins. Klassy stores config under ~/.config/klassy/ (subdir), so
  # the path is "klassy/klassyrc" — managing it here makes it a read-only symlink
  # into the store; re-tune in the GUI by editing this block, not System Settings
  # (which can't write the symlink), then rebuild. The bundled-preset catalogue
  # (~/.config/klassy/windecopresetsrc) is package data Klassy regenerates, so we
  # deliberately leave it unmanaged. RefreshedConfig tracks the Klassy version
  # that wrote this; bump it if a future Klassy upgrade needs to re-migrate.
  xdg.configFile."klassy/klassyrc".text = ''
    [ButtonBehaviour]
    ShowCloseOutlineNormallyActive=true
    ShowCloseOutlineNormallyInactive=true
    ShowOutlineNormallyActive=true
    ShowOutlineNormallyInactive=true
    VaryColorCloseBackgroundActive=Opaque
    VaryColorCloseBackgroundInactive=Opaque
    VaryColorCloseOutlineInactive=Opaque
    VaryColorOutlineActive=Transparent

    [ButtonColors]
    ButtonBackgroundColorsActive=AccentTrafficLights
    ButtonBackgroundColorsInactive=AccentTrafficLights
    ButtonBackgroundOpacityActive=87
    ButtonBackgroundOpacityInactive=38
    LockButtonColorsActiveInactive=false

    [ButtonSizing]
    ButtonCustomCornerRadius=1
    ButtonSpacingRight=6
    FullHeightButtonSpacingRight=2
    IntegratedRoundedRectangleBottomPadding=2
    LockButtonSpacingLeftRight=true
    LockFullHeightButtonSpacingLeftRight=true

    [Global]
    LookAndFeelSet=org.kde.breezedark.desktop
    RefreshedConfig=6.5.3

    [TitleBarSpacing]
    PercentMaximizedTopBottomMargins=20
    TitleBarBottomMargin=6
    TitleBarLeftMargin=8
    TitleBarRightMargin=8
    TitleBarTopMargin=6

    [Windeco]
    AnimationsSpeedRelativeSystem=-2
    BoldButtonIcons=BoldIconsBold
    BoldTitle=false
    ButtonIconStyle=StyleOxygen
    ButtonShape=ShapeSmallCircle
    ColorizeWindowOutlineWithButton=false
    DrawTitleBarSeparator=false
    IconSize=IconSmall
    SystemIconSize=SystemIcon18
    WindowCornerRadius=6

    [WindowOutlineStyle]
    LockWindowOutlineStyleActiveInactive=true
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
        name = "FiraMono Nerd Font Mono"; # trialling Fira Mono (was JetBrainsMono Nerd Font Mono)
        size = 11;
      };
    };
  };

  # Ghostty: Mitchell Hashimoto's GPU-accelerated terminal, added alongside
  # Konsole to A/B them. Same JetBrainsMono Nerd Font coding font as Konsole and
  # VSCodium (nerd-fonts.jetbrains-mono in home.packages). "Catppuccin Mocha" is
  # one of Ghostty's built-in themes (exact name, capitalised with a space — as
  # listed by `ghostty +list-themes`), so it matches the desktop's Catppuccin
  # Mocha palette without any extra package. Ligatures are on by default, so
  # JetBrains Mono's programming ligatures render as in VSCodium. Being a GTK app
  # it sits outside the Qt/Kvantum styling, hence theming it here directly.
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "FiraMono Nerd Font Mono"; # trialling Fira Mono (was JetBrainsMono Nerd Font Mono)
      font-size = 10;
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
        # 13px ≈ Ghostty's 10pt (font-size above): VSCodium sizes in pixels, Ghostty
        # in points, so px = pt × 96/72 (×1.33) keeps the two visually matched.
        "editor.fontSize" = 13;
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
    neovim # editor; config is hand-managed LazyVim in ~/.config/nvim (NOT via
    # programs.neovim — see the note near programs.zsh — so HM doesn't own init.lua)
    nil # Nix LSP for VSCodium's nix-ide extension (nix.serverPath above)
    nixd # Nix LSP for Neovim/LazyVim — evaluates a flake for NixOS option +
    # package completion (the target flake + exprs live in
    # ~/.config/nvim/lua/plugins/nixd.lua, currently ~/nixos; LazyVim's lang.nix
    # default nil_ls is disabled there). VSCodium stays on nil.
    elan # Lean toolchain manager (used by the Lean 4 extension)
    gcc # C/C++ compiler — provides `cc`/`gcc` so nvim-treesitter (LazyVim) can
    # compile its parsers; also a general dev compiler (NixOS has none in PATH by default)
    tree-sitter # tree-sitter CLI — nvim-treesitter's `main` branch builds parsers
    # via `tree-sitter build` (not cc directly), so the CLI is required alongside gcc
    # Nix language tooling for LazyVim's lang.nix extra (Mason can't install these
    # on NixOS, so they come from here): nixd = LSP (above), nixfmt = formatter
    # (conform's "nixfmt"), statix = linter (nvim-lint).
    nixfmt # `nixfmt` binary — conform formatter for .nix in LazyVim's lang.nix
    statix # Nix linter used by LazyVim's lang.nix (nvim-lint)
    # LazyVim LSP/formatter tools. Mason is DISABLED on NixOS (it can't link its
    # prebuilt downloads — see ~/.config/nvim/lua/plugins/nixos.lua), so every
    # server/formatter/linter comes from here and is found on $PATH. Add the
    # matching package whenever a new LazyVim lang extra is enabled.
    vscode-langservers-extracted # jsonls (vscode-json-language-server) + css/html/eslint (lang.json)
    marksman # Markdown LSP (lang.markdown)
    markdownlint-cli2 # Markdown linter + formatter (lang.markdown)
    markdown-toc # Markdown table-of-contents formatter (lang.markdown)
    prettier # formatter for markdown/json/web (lang.markdown, lang.json)
    lua-language-server # lua_ls — LazyVim core LSP for editing this config
    google-chrome # 1Password-trusted by default; native Wayland via NIXOS_OZONE_WL
    solaar # Logitech device manager — used to disable the G502's high-resolution
    # scrolling (set "Scroll Wheel Resolution"/hi-res OFF in the GUI once; the
    # autostart service below re-applies it on each reconnect). Needs the udev
    # rules from hardware.logitech.wireless.enable in common.nix.
    # OrcaSlicer (Bambu X1C slicer). The stock nixpkgs build (2.3.2) renders a
    # blank 3D viewport and heap-crashes on this hybrid GPU, so this is a
    # from-source v2.4.0-beta build via the overlay in pkgs/orca-slicer.nix
    # (clang + Eigen 5 + wxWidgets 3.3 EGL canvas + Mesa-pinned + dark GTK).
    # 3D renders, HiDPI scaling is correct; it still aborts ungracefully on quit
    # (harmless — config saves first). Replaced the old Flatpak.
    orca-slicer
    nerd-fonts.jetbrains-mono # coding font w/ Nerd Font glyphs (VSCodium; kept so the Fira trial is easy to revert)
    nerd-fonts.fira-mono # trialling this in the terminals (Konsole + Ghostty); see programs.konsole/ghostty above
    # Klassy window decoration. Binary KDecoration3 plugin
    # (lib/qt-6/plugins/org.kde.kdecoration3/org.kde.klassy.so) selected by
    # programs.plasma.workspace.windowDecorations above. Provides the "Klassy"
    # title bars — rounded corners, accent-coloured buttons, thin window outline.
    # Also bundles an application style (styles/klassy6.so) we leave unselected so
    # Kvantum keeps owning the widgets/scrollbars.
    klassy
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

  # (OrcaSlicer was previously a Flatpak here; it's now the native overlay build
  # in home.packages above, so the nix-flatpak declaration was removed. The
  # nix-flatpak module is still wired in flake.nix and the system flatpak service
  # in common.nix is still enabled, ready if another Flatpak app is wanted.)

  # Autostart Solaar (hidden, in the tray) in the graphical session. Solaar only
  # re-applies its saved device settings — notably the G502's hi-res-scroll OFF —
  # while it's running, so this keeps the setting in effect across reconnects and
  # reboots. Configure the actual toggle once in the Solaar GUI; it's saved to
  # ~/.config/solaar/config.yaml and re-applied by this service on each connect.
  systemd.user.services.solaar = {
    Unit = {
      Description = "Solaar - Logitech device manager (applies saved settings)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
