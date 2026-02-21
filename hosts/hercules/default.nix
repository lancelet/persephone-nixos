# NixOS configuration for hercules (Threadripper 3970X workstation)

{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "hercules";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # YubiKey as sudo replacement (touch key instead of password)
  # Key mapping stored per-user in ~/.config/Yubico/u2f_keys
  security.pam.u2f = {
    enable = true;
    control = "sufficient";  # success = skip password; key absent = fall back to password
    settings.cue = true;     # print "Please touch the device" prompt
  };
  security.pam.services.sudo.u2fAuth = true;

  # YubiKey touch detector — shows a KDE notification when the key needs to be touched
  programs.yubikey-touch-detector = {
    enable = true;
    libnotify = true;  # fires native desktop notifications (KDE shows these as popups)
  };

  # SSH access for remote administration
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILf5YJT1mbjKrdGxot7XiBCspxD8Uf9wKz1nK/m+YEWQ j.s.merritt@gmail.com"
  ];

  system.stateVersion = "25.11";
}
