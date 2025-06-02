{ pkgs, ... }:
{
  gtk = {
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
