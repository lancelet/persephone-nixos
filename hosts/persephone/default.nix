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

  # Disable CPU bus-lock detection. OrcaSlicer's slicing threads emit a flood of
  # misaligned locked atomics; with detection on, each raises a #DB trap + printk
  # (`took a bus_lock trap` / `handle_bus_lock` in journalctl), which throttles
  # the slicer and spams the log. split_lock_detect=off lets them run as ordinary
  # harmless bus locks. NOTE: this is NOT the hard-lockup fix — disabling
  # detection was verified live (bus_traps=0 in journalctl) yet the machine still
  # froze; the lockup is the dGPU RTD3 resume hang (see finegrained below). This
  # param is kept only to stop the trap throttle/spam. Boot param → needs reboot.
  boot.kernelParams = [ "split_lock_detect=off" ];

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

  # Fine-grained (RTD3) power management — DISABLED. It lets the idle dGPU drop to
  # D3cold, but on this machine the D3cold->D0 *resume* hard-locks the box (total
  # freeze, power-button reset, no kernel log): OrcaSlicer's GL init touches the
  # dGPU (EGL defaults to the NVIDIA vendor here), waking it from D3cold — the
  # lockup boot's last GPU event is `nvidia ...: Enabling HDA controller` (a
  # resume), then the journal dies cold. Measured battery benefit of RTD3 here is
  # ~0W anyway (brightness is the only real lever), so leaving the dGPU parked at
  # D0 costs nothing and stops the hang. Re-enable only with a newer driver/kernel
  # that fixes RTD3 resume, and re-test OrcaSlicer specifically.
  hardware.nvidia.powerManagement.finegrained = false;

  # Cap battery charge at 90% for long-term cell health, re-asserted at each boot
  # (BAT1 is the Framework 16's battery). Raise to 100 for maximum runtime per
  # charge, or lower (e.g. 80) for maximum lifespan.
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 90"
  ];

  # Fingerprint authentication (fprintd itself is enabled by nixos-hardware).
  # SDDM substacks to the login PAM service for auth, so disable fprintd on
  # login (not sddm) to avoid a 30s fingerprint timeout at the login screen.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.login.fprintAuth = false;

  system.stateVersion = "25.11";
}
