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
    # Standard Breeze Dark. Owning this here overwrites the orphaned Stylix /
    # OsakaJade (green) theming left in ~/.config by the previous setup.
    workspace = {
      colorScheme = "BreezeDark";
      lookAndFeel = "org.kde.breezedark.desktop";
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
        "editor.fontFamily" = "'JetBrains Mono', monospace"; # coding font (pkg below)
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
    jetbrains-mono # editor coding font (see editor.fontFamily above)
  ];
}
