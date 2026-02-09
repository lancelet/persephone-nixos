# Theme sets — change `active` to switch the entire system theme.
#
# Each theme defines:
#   stylix  — base16 scheme, wallpaper, polarity (always required)
#   vscode  — marketplace extension + colorTheme override (optional;
#             when absent Stylix auto-generates the VS Code theme)
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
  };
}
