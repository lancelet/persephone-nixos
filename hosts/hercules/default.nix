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
