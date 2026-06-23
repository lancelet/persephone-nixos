# OrcaSlicer overlay for persephone/hercules — a from-source build of
# v2.4.0-beta that fixes what the stock nixpkgs 2.3.2 gets wrong on these
# machines. Full investigation: memory/project_orca_slicer_packaging.md.
#
# Why each override exists:
#  - v2.4.0-beta from source — nixpkgs ships 2.3.2, whose 3D viewport renders
#    blank here (upstream GL regression #12758). 2.4.0 renders correctly.
#  - clangStdenv — the stock gcc build heap-crashes at startup inside the
#    prebuilt Bambu network plugin; building with clang (the toolchain the
#    upstream Flatpak uses) fixes the startup crash.
#  - Eigen 5.0.1 — 2.4.0 requires Eigen 5; nixpkgs only has 3.4.1. Injected into
#    OrcaSlicer alone (via .override, not a global overlay) so opencv/cgal/
#    openvdb keep their existing eigen and don't rebuild.
#  - wxWidgets 3.3 with EGL canvas — 2.4.0 needs wx >= 3.3. Leaving the EGL GL
#    canvas enabled lets the app run on native Wayland, which renders the
#    viewport (Mesa-pinned, see wrapper) AND scales correctly on fractional
#    HiDPI. wx 3.3 dropped the withCurl/withPrivateFonts/withEGL arguments, so a
#    makeOverridable shim swallows the legacy flags OrcaSlicer's package.nix
#    still passes.
#  - drop pr-7650 patch — its GUI_App.cpp hunk no longer applies to 2.4.0; it's
#    only a cosmetic update-nag toggle.
#  - format hardening off + extra -Wno flags — clang is stricter than gcc on the
#    bundled imgui (-Wformat-security, and gcc-only -Wno-* options clang rejects
#    as unknown-warning-option). Silence them; they're not real defects.
#
# KNOWN COSMETIC ISSUE: an ungraceful abort on quit — heap corruption in the
# closed-source Bambu network plugin's std::locale teardown (a libstdc++ ABI
# mismatch we can't patch). Config is saved before it runs, so it's harmless.
# Only the plugin's own bundled runtime (what the Flatpak ships) avoids it.

final: prev:
let
  # wx 3.3 shim: accept and ignore the legacy flags orca passes; keep the EGL
  # canvas enabled (the 3.3 default) so wxHAS_EGL is ON and the app uses native
  # Wayland instead of forcing the X11/GLX backend.
  wxOrca = prev.lib.makeOverridable (
    {
      withCurl ? true,
      withPrivateFonts ? true,
      withWebKit ? true,
      withEGL ? true,
    }:
    prev.wxwidgets_3_3.override { inherit withWebKit; }
  ) { };

  eigen5 = prev.eigen.overrideAttrs (o: {
    version = "5.0.1";
    src = prev.fetchFromGitLab {
      owner = "libeigen";
      repo = "eigen";
      rev = "5.0.1";
      hash = "sha256-8TW1MUXt2gWJmu5YbUWhdvzNBiJ/KIVwIRf2XuVZeqo=";
    };
    # The nixpkgs 3.4.1 test-fix patch doesn't apply to 5.0.1.
    patches = [ ];
  });

  # Keep nanum (the #11641 missing-font crash workaround) and add real UI fonts
  # so the slicer matches the desktop instead of the bare DejaVu fallback.
  fontsConf = prev.makeFontsConf {
    fontDirectories = [
      prev.nanum
      prev.dejavu_fonts
      prev.noto-fonts
    ];
  };
in
{
  orca-slicer =
    (prev.orca-slicer.override {
      stdenv = prev.clangStdenv;
      eigen = eigen5;
      wxwidgets_3_1 = wxOrca;
      # Build gst-plugins-good with GTK support so it ships the `gtksink`
      # element. OrcaSlicer's printer-camera live-view needs it on native
      # Wayland ("requires the GStreamer GTK video sink"); the default build
      # has gtkSupport=false. Swap the variant in (rather than add a second
      # copy) so the GST plugin path has no duplicate plugins.
      gst_all_1 = prev.gst_all_1 // {
        gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
          gtkSupport = true;
        };
      };
    }).overrideAttrs
      (old: {
        version = "2.4.0-beta";
        src = prev.fetchFromGitHub {
          owner = "OrcaSlicer";
          repo = "OrcaSlicer";
          rev = "v2.4.0-beta";
          hash = "sha256-bx4faVtEkcqBXzSXBXIsntDA4EFxDxWyUeI583tYhdw=";
        };

        patches = builtins.filter (p: !(prev.lib.hasInfix "update-check" (toString p))) old.patches;

        hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "format" ];
        env = old.env // {
          NIX_CFLAGS_COMPILE =
            old.env.NIX_CFLAGS_COMPILE
            + " -Wno-unknown-warning-option -Wno-error=format-security -Wno-format-security";
        };

        # Runtime wrapper additions (appended; a later --set wins over the
        # original derivation's, so these override its nanum-only fonts):
        #  - FONTCONFIG_FILE: our richer font set (nanum + DejaVu + Noto).
        #  - GTK_THEME=Adwaita:dark: GTK draws the base window/panels; without
        #    this they render light under KDE. OrcaSlicer's own UI follows the
        #    system colour scheme and goes dark to match.
        #  - __EGL_VENDOR_LIBRARY_FILENAMES -> Mesa: on the hybrid GPU, EGL
        #    otherwise defaults to the NVIDIA vendor (blank viewport); pin it to
        #    the Mesa/AMD vendor so native-Wayland EGL renders. No-op on the
        #    Mesa-only workstation.
        #  - LC_ALL=C: matches the locale used in testing; the gcc startup crash
        #    needed it and clang may have made it unnecessary, but it's kept for
        #    safety. Switch to C.UTF-8 if any non-ASCII UI text looks wrong.
        preFixup = (old.preFixup or "") + ''
          gappsWrapperArgs+=(
            --set FONTCONFIG_FILE "${fontsConf}"
            --set GTK_THEME "Adwaita:dark"
            --set LC_ALL "C"
            --set __EGL_VENDOR_LIBRARY_FILENAMES "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
          )
        '';
      });
}
