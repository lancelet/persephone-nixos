# Theme sets — change `active` to switch the entire system theme.
#
# Each theme defines:
#   stylix   — base16 scheme, wallpaper, polarity (always required)
#   vscode   — marketplace extension + colorTheme override (optional;
#              when absent Stylix auto-generates the VS Code theme)
#   ghostty  — terminal palette overrides to match Omarchy exactly
#              (Stylix base16 can't express all 16 distinct ANSI colors)
let
  active = "osaka-jade";
in
{
  inherit active;

  osaka-jade = {
    stylix = {
      base16Scheme = ./osaka-jade.yaml;
      image = ./wallpapers/1-osaka-jade-bg.jpg;
      polarity = "dark";
    };
    vscode = {
      extension = {
        publisher = "jovejonovski";
        name = "ocean-green";
        version = "1.1.2";
        sha256 = "1kmwpag4hv9i4a19x688gn4z3y8ivh9g3817aavsvjcp7agn6hxi";
      };
      themeName = "Ocean Green: Dark";
    };
    neovim = {
      colorscheme = "bamboo";
      plugin = "bamboo-nvim";
    };
    ghostty = {
      # Omarchy's full 16-color terminal palette. Stylix gets the normal
      # colors (1-6) right but repeats them for bright variants (9-14)
      # and uses wrong values for 0, 3, 7, 15. These overrides fix that.
      palette = [
        "0=#23372B" # black        (dark green, not background)
        "1=#FF5345" # red
        "2=#549E6A" # green
        "3=#459451" # yellow       (Omarchy's "yellow" is a dark green)
        "4=#509475" # blue
        "5=#D2689C" # magenta
        "6=#2DD5B7" # cyan
        "7=#F6F5DD" # white        (warm cream, not foreground green)
        "8=#53685B" # bright black
        "9=#DB9F9C" # bright red   (soft salmon, not repeated red)
        "10=#63B07A" # bright green
        "11=#E5C736" # bright yellow
        "12=#ACD4CF" # bright blue  (light teal, not repeated jade)
        "13=#75BBB3" # bright magenta (teal, not repeated magenta)
        "14=#8CD3CB" # bright cyan
        "15=#9EEBB3" # bright white (mint green)
      ];
      cursor-color = "#D7C995";
    };
  };
}
