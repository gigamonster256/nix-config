{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  home.packages = lib.mkIf config.programs.zsh.enable (with pkgs; [
    fzf
    tmux
    eternal-terminal
    flash
    extract
  ]);

  programs.oh-my-posh = {
    enable = mkDefault config.programs.zsh.enable;
    settings = mkDefault (import ./posh-config.nix);
  };

  programs.zsh = {
    syntaxHighlighting.enable = mkDefault true;
    autosuggestion.enable = mkDefault true;
    # historySubstringSearch.enable = true;
    initExtraBeforeCompInit =
      /*
      bash
      */
      ''
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
    initExtra =
      /*
      bash
      */
      "";
  };
  home.shellAliases = {
    l = mkDefault "ls";
    gr = mkDefault "cd $(git rev-parse --show-toplevel)";
  };
}
