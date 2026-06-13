# NixOS configuration for persephone (Framework 16, AMD AI 300 + RTX 5070)

{
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "persephone";

  # Bootloader (GRUB for a HiDPI-friendly boot menu).
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

  # Touchpad — two-finger click = right-click.
  services.libinput.touchpad = {
    tapping = false;
    clickMethod = "clickfinger";
  };

  # NVIDIA PRIME (RTX 5070 + AMD iGPU). The nixos-hardware module handles
  # the bulk of the NVIDIA setup; we just supply bus IDs and reverse sync
  # (the latter enables external displays on the rear USB-C port).
  hardware.nvidia.prime = {
    reverseSync.enable = true;
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };

  # Fingerprint authentication (fprintd itself is enabled by nixos-hardware).
  # SDDM substacks to the login PAM service for auth, so disable fprintd on
  # login (not sddm) to avoid a 30s fingerprint timeout at the login screen.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.login.fprintAuth = false;

  system.stateVersion = "25.11";
}
