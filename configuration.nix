# NixOS configuration for persephone

{ lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader (GRUB for HiDPI-friendly boot menu).
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    gfxmodeEfi = "1024x768";
    font = lib.mkForce "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf";
    fontSize = 36;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "persephone";

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Touchpad — macOS-style two-finger click = right-click (X11 fallback)
  services.libinput.touchpad = {
    tapping = false;
    clickMethod = "clickfinger";
  };

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

  # NVIDIA PRIME configuration (Framework 16 with RTX 5070)
  # The nixos-hardware module handles most settings; we just need bus IDs and reverse sync
  hardware.nvidia.prime = {
    reverseSync.enable = true;  # Enables external displays on rear USB-C port
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.jsm = {
    isNormalUser = true;
    description = "Jonathan Merritt";
    extraGroups = [ "networkmanager" "wheel" ];
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

  # Fingerprint authentication (fprintd itself enabled by nixos-hardware)
  # Lock screen fingerprint works via the kde-fingerprint PAM service.
  # SDDM substacks to login for auth, so disable fprintd on login
  # (not sddm) to avoid a 30s fingerprint timeout at the login screen.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.login.fprintAuth = false;

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
    base16Scheme = ./osaka-jade.yaml;
    image = ./wallpapers/1-osaka-jade-bg.jpg;
    polarity = "dark";

    fonts = {
      monospace = { package = pkgs.nerd-fonts.jetbrains-mono; name = "JetBrainsMono Nerd Font Mono"; };
      sansSerif = { package = pkgs.noto-fonts; name = "Noto Sans"; };
      serif = { package = pkgs.noto-fonts; name = "Noto Serif"; };
      emoji = { package = pkgs.noto-fonts-color-emoji; name = "Noto Color Emoji"; };
    };

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
    pciutils  # For lspci to verify GPU bus IDs
    curl
    wget
    (let blender-cuda = blender.override { cudaSupport = true; };
    in runCommand "blender" { nativeBuildInputs = [ makeWrapper ]; } ''
      mkdir -p $out/bin $out/share/applications
      makeWrapper ${blender-cuda}/bin/blender $out/bin/blender \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER "NVIDIA-G0" \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set __VK_LAYER_NV_optimus "NVIDIA_only"
      for dir in ${blender-cuda}/share/*; do
        name=$(basename "$dir")
        [ "$name" = "applications" ] && continue
        ln -s "$dir" $out/share/$name
      done
      for f in ${blender-cuda}/share/applications/*.desktop; do
        substitute "$f" $out/share/applications/$(basename "$f") \
          --replace-quiet "${blender-cuda}/bin/blender" "$out/bin/blender"
      done
    '')
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.settings.substituters = [ "https://cuda-maintainers.cachix.org" ];
  nix.settings.trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
