# Shared NixOS configuration for all machines.

{ pkgs, ... }:

let
  theme = import ./theme.nix;
  current = theme.${theme.active};
in
{
  # Enable networking
  networking.networkmanager.enable = true;
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.jsm = {
    isNormalUser = true;
    description = "Jonathan Merritt";
    extraGroups = [ "networkmanager" "wheel" "_1password" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jsm" ];
  };

  # macOS-style keyboard shortcuts via xremap
  services.xremap = {
    enable = true;
    serviceMode = "user";
    userName = "jsm";
    withKDE = true;

    config = {
      # Single key remapping
      modmap = [
        {
          name = "CapsLock to Escape";
          remap = {
            CapsLock = "Esc";
          };
        }
      ];

      # Combo remapping (first match wins)
      keymap = [
        # 1. Terminal overrides (Ghostty) — must be listed first
        {
          name = "Terminal (Ghostty)";
          application = { only = [ "com.mitchellh.ghostty" ]; };
          remap = {
            # Clipboard / window management (Ctrl+Shift variants for terminal)
            Super-c = "C-Shift-c";
            Super-v = "C-Shift-v";
            Super-x = "C-Shift-x";
            Super-t = "C-Shift-t";
            Super-w = "C-Shift-w";
            Super-n = "C-Shift-n";
            Super-a = "C-Shift-a";
            Super-f = "C-Shift-f";
            Super-q = "C-Shift-q";
            Super-z = "C-z";
            Super-Shift-z = "C-y";
            Super-s = "C-s";

            # Text navigation (duplicated for self-containment)
            Super-Left = "Home";
            Super-Right = "End";
            Super-Up = "C-Home";
            Super-Down = "C-End";
            Alt-Left = "C-Left";
            Alt-Right = "C-Right";
            Alt-Backspace = "C-Backspace";
            Super-Shift-Left = "Shift-Home";
            Super-Shift-Right = "Shift-End";
          };
        }

        # 2. Global macOS-style editing shortcuts
        {
          name = "Global macOS shortcuts";
          remap = {
            Super-c = "C-c";
            Super-v = "C-v";
            Super-x = "C-x";
            Super-z = "C-z";
            Super-Shift-z = "C-y";
            Super-a = "C-a";
            Super-s = "C-s";
            Super-f = "C-f";
            Super-w = "C-w";
            Super-q = "Alt-F4";
            Super-t = "C-t";
            Super-n = "C-n";
          };
        }

        # 3. Text navigation
        {
          name = "Text navigation";
          remap = {
            Super-Left = "Home";
            Super-Right = "End";
            Super-Up = "C-Home";
            Super-Down = "C-End";
            Alt-Left = "C-Left";
            Alt-Right = "C-Right";
            Alt-Backspace = "C-Backspace";
            Super-Shift-Left = "Shift-Home";
            Super-Shift-Right = "Shift-End";
          };
        }

        # 4. Window management / KDE integration
        {
          name = "Window management";
          remap = {
            Super-Tab = "Alt-Tab";
            Super-Space = "Alt-Space";
            Super-LeftBrace = "Alt-Left";
            Super-RightBrace = "Alt-Right";
          };
        }
      ];
    };
  };

  # Stylix — unified theming (Osaka Jade)
  stylix = {
    enable = true;
    inherit (current.stylix) base16Scheme image polarity;

    fonts = {
      monospace = { package = pkgs.nerd-fonts.jetbrains-mono; name = "JetBrainsMono Nerd Font Mono"; };
      sansSerif = { package = pkgs.noto-fonts; name = "Noto Sans"; };
      serif = { package = pkgs.noto-fonts; name = "Noto Serif"; };
      emoji = { package = pkgs.noto-fonts-color-emoji; name = "Noto Color Emoji"; };
    };

    fonts.sizes.terminal = 10.5;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    pciutils
    curl
    wget
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.settings.max-jobs = "auto";
  nix.settings.substituters = [
    "https://cuda-maintainers.cachix.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
