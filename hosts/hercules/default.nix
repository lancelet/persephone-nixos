# NixOS configuration for hercules (Threadripper 3970X workstation)

{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "hercules";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # YubiKey touch as a sudo password replacement.
  # Key mapping is stored per-user in ~/.config/Yubico/u2f_keys.
  security.pam.u2f = {
    enable = true;
    control = "sufficient"; # success = skip password; key absent = fall back to password
    settings.cue = true; # print "Please touch the device" prompt
  };
  security.pam.services.sudo.u2fAuth = true;

  system.stateVersion = "25.11";
}
