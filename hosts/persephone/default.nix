# NixOS configuration for persephone (Framework 16, AMD AI 300 + RTX 5070)

{ lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "persephone";

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

  # Touchpad — macOS-style two-finger click = right-click (X11 fallback)
  services.libinput.touchpad = {
    tapping = false;
    clickMethod = "clickfinger";
  };

  # NVIDIA PRIME configuration (Framework 16 with RTX 5070)
  # The nixos-hardware module handles most settings; we just need bus IDs and reverse sync
  hardware.nvidia.prime = {
    reverseSync.enable = true;  # Enables external displays on rear USB-C port
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };

  # Ollama (local LLM inference with CUDA)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  # Fingerprint authentication (fprintd itself enabled by nixos-hardware)
  # Lock screen fingerprint works via the kde-fingerprint PAM service.
  # SDDM substacks to login for auth, so disable fprintd on login
  # (not sddm) to avoid a 30s fingerprint timeout at the login screen.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.login.fprintAuth = false;

  environment.systemPackages = with pkgs; [
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

  system.stateVersion = "25.11";
}
