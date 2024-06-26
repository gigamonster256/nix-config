{pkgs, ...}: {
  home.packages = with pkgs; [
    fzf
    tmux
    eternal-terminal
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  programs.oh-my-posh = {
    enable = true;
    settings = import ./posh-config.nix;
  };

  programs.zsh = {
    enable = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    initExtra = ''
      # Plugins
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

      # Shell integrations
      eval "$(fzf --zsh)"
    '';
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -l";
      la = "ls -la";
      l = "ls";
    };
  };
}
