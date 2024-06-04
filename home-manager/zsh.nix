{pkgs, ...}: {
  home.packages = with pkgs; [
    meslo-lgs-nf
  ];
  programs.zsh = {
    enable = true;
    initExtra = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };
}
