{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    fzf
    tmux
    eternal-terminal
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
      eval "$(${lib.getExe pkgs.fzf} --zsh)"
      # catppuccin mocha theme
      export FZF_DEFAULT_OPTS=" \
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    '';
    initExtra = let
      run = cmd: lib.getExe pkgs.${cmd};
      ddOpts = "status=progress conv=fsync,noerror bs=64k";
      fromPipeddOpts = "iflag=fullblock oflag=direct ${ddOpts}";
      fileType = file: "$(${run "file"} ${file} --mime-type -b)";
      zstdcat = "${pkgs.zstd}/bin/zstdcat";
      xzcat = "${pkgs.xz}/bin/xzcat";
      dd = "${pkgs.coreutils}/bin/dd";
      tar = "${run "gnutar"}";
      unzip = "${run "unzip"}";
    in ''
      flash(){
          if [ ${fileType "$1"} = "application/zstd" ]; then
            echo "Flashing zst using zstdcat | dd"
            ( set -x; ${zstdcat} $1 | sudo ${dd} of=$2 ${fromPipeddOpts} )
          elif [ ${fileType "$1"} = "application/x-xz" ]; then
            echo "Flashing xz using xzcat | dd"
            ( set -x; ${xzcat} $1 | sudo ${dd} of=$2 ${fromPipeddOpts} )
          else
            echo "Flashing arbitrary file $1 to $2"
            ( set -x; sudo ${dd} if=$1 of=$2 ${ddOpts} )
          fi
      }
      extract(){
         if [ -f $1 ] ; then
             case $1 in
                 *.tar.bz2) ${tar} xjf $1;;
                 *.tar.gz)  ${tar} xzf $1;;
                 *.tar)     ${tar} xf $1;;
                 *.tbz2)    ${tar} xjf $1;;
                 *.tgz)     ${tar} xzf $1;;
                 *.zip)     ${unzip} $1;;
                 *)         echo "'$1' cannot be extracted via extract()";;
             esac
         else
             echo "'$1' is not a valid file"
         fi
      }
    '';
  };
  home.shellAliases = {
    ls = "ls --color=auto";
    ll = "ls -l";
    la = "ls -la";
    l = "ls";
    gr = "cd $(git rev-parse --show-toplevel)";
  };
}
