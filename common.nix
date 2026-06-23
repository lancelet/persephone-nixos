# Shared NixOS configuration for all machines.
#
# Deliberately minimal: a bootable KDE Plasma 6 desktop with networking,
# audio, and the jsm user. Add anything else either here (system-wide) or in
# home.nix (per-user).

{ pkgs, ... }:

{
  # Networking
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "8.8.8.8"
    "1.1.1.1"
  ];
  # OrcaSlicer (home.nix) discovers Bambu Lab printers via a UDP broadcast on
  # port 2021; the default firewall drops it, so the printer never appears.
  # Orca has no manual-IP fallback, so this is required for LAN-mode binding.
  # Add 1990/2022 here too if discovery still fails on some networks.
  networking.firewall.allowedUDPPorts = [ 2021 ];
  hardware.bluetooth.enable = true;

  # Logitech wireless support: installs the udev rules so Solaar (home.nix) can
  # talk to the Lightspeed receiver as a normal user. Used to turn OFF the G502's
  # high-resolution scrolling (which emits ~10 events per wheel detent → over-
  # scrolling in terminals/Neovim) while keeping the ratchet, no free-spin drift.
  hardware.logitech.wireless.enable = true;

  # Power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Locale / time
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";

  # Keyboard (applies to console and the Wayland session)
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  # KDE Plasma 6 desktop on Wayland, with the SDDM display manager.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Flatpak, for apps that don't package cleanly in nixpkgs. OrcaSlicer was the
  # original motivating case (the nixpkgs build renders a blank 3D viewport and
  # heap-corrupts on this hybrid AMD-iGPU/NVIDIA-dGPU system), but it's now a
  # native from-source build instead — see pkgs/orca-slicer.nix. Flatpak is kept
  # enabled for any future such app. (Plasma 6 provides the xdg-desktop-portal
  # backend.)
  services.flatpak.enable = true;

  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account. Set a password with `passwd` after first switch.
  users.users.jsm = {
    isNormalUser = true;
    description = "Jonathan Merritt";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Run Chromium/Electron apps (VSCode, etc.) as native Wayland so they render
  # crisply at fractional display scaling instead of being bitmap-scaled.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # 1Password (CLI + GUI). polkitPolicyOwners lets jsm authenticate system
  # integration (e.g. unlock with fingerprint / system auth).
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jsm" ];
  };
  # Zen isn't on 1Password's built-in browser allowlist, so trust its wrapped
  # binary explicitly to enable the browser-extension integration.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ".zen-wrapped";
    mode = "0755";
  };

  # A bare handful of system tools. Per-user packages live in home.nix.
  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    pciutils # lspci / setpci — inspect PCI devices (GPUs, expansion modules)
    usbutils # lsusb — inspect USB devices
  ];

  # Nix daemon settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
