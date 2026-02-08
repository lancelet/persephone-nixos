# NixOS configuration for persephone

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "persephone";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
    packages = [ ];
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

  # Git
  programs.git = {
    enable = true;
    config = {
      user.name = "Jonathan Merritt";
      user.email = "j.s.merritt@gmail.com";
    };
  };

  # Remap CapsLock to Escape (kernel-level, works on Wayland + X11)
  services.keyd = {
    enable = true;
    keyboards.default.settings.main = {
      capslock = "escape";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    gh
    pciutils  # For lspci to verify GPU bus IDs
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
