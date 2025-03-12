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
    # historySubstringSearch.enable = true;
    initExtraBeforeCompInit = ''
      # Plugins
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Extra colors for directory listings.
      eval "$(${pkgs.coreutils}/bin/dircolors -b)"

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

      # tmux integration
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
    initExtra = ''
      flash(){
          if [ $(${pkgs.file}/bin/file $1 --mime-type -b) = "application/zstd" ]; then
            echo "Flashing zst using zstdcat | dd"
            ( set -x; ${pkgs.zstd}/bin/zstdcat $1 | sudo dd of=$2 status=progress iflag=fullblock oflag=direct conv=fsync,noerror bs=64k )
          elif [ $(${pkgs.file}/bin/file $1 --mime-type -b) = "application/x-xz" ]; then
            echo "Flashing xz using xzcat | dd"
            ( set -x; ${pkgs.xz}/bin/xzcat $1 | sudo dd of=$2 status=progress iflag=fullblock oflag=direct conv=fsync,noerror bs=64k )
          else
            echo "Flashing arbitrary file $1 to $2"
            ( set -x; sudo dd if=$1 of=$2 status=progress conv=sync,noerror bs=64k )
          fi
      }
      extract(){
         if [ -f $1 ] ; then
             case $1 in
                 *.tar.bz2)   tar xjf $1;;
                 *.tar.gz)    tar xzf $1;;
                 *.bz2)       bunzip2 $1;;
                 *.rar)       rar x $1;;
                 *.gz)        gunzip $1;;
                 *.tar)       tar xf $1;;
                 *.tbz2)      tar xjf $1;;
                 *.tgz)       tar xzf $1;;
                 *.zip)       unzip $1;;
                 *.Z)         uncompress $1;;
                 *.7z)        7z x $1;;
                 *)           echo "'$1' cannot be extracted via extract()";;
             esac
         else
             echo "'$1' is not a valid file"
         fi
      }
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
