{pkgs, ...}: {
  home.packages = with pkgs; [
    btop-with-themes
  ];
}
