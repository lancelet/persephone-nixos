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
    settings.user = {
      name = "Jonathan Merritt";
      email = "j.s.merritt@gmail.com";
    };
  };

  # Atuin: magical shell history (Ctrl-R search, etc.). Zsh integration is
  # enabled by default.
  programs.atuin.enable = true;

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
  };

  # VSCodium with extensions managed declaratively. Uses the dedicated
  # programs.vscodium module so config lands in VSCodium's own paths
  # (programs.vscode now always writes to upstream VS Code's paths).
  programs.vscodium = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim # Vim keybindings
        jnoortheen.nix-ide # Nix syntax highlighting + LSP
        leanprover.lean4 # Lean 4 language support
      ];
      userSettings = {
        # Drive nix-ide's language features with nil (provided below).
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
      };
    };
  };

  # Zen browser (module imported above). Native-Wayland; pairs with the
  # system-level 1Password browser trust configured in common.nix.
  programs.zen-browser.enable = true;

  # User packages.
  home.packages = with pkgs; [
    nil # Nix language server (used by nix-ide above)
    elan # Lean toolchain manager (used by the Lean 4 extension)
    google-chrome # 1Password-trusted by default; native Wayland via NIXOS_OZONE_WL
  ];
}
