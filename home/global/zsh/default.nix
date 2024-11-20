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
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;
    initExtra = ''
      # Plugins
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Extra colors for directory listings.
      eval "$(${pkgs.coreutils}/bin/dircolors -b)"

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

      # tmux integration # does not work when using iterm2 with tmux control mode
      # zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

      # Shell integrations
      # fzf
      eval "$(${pkgs.fzf}/bin/fzf --zsh)"
      # catppuccin mocha theme
      export FZF_DEFAULT_OPTS=" \
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    '';
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -l";
      la = "ls -la";
      l = "ls";
      gr = "cd $(git rev-parse --show-toplevel)";
    };
  };
}
