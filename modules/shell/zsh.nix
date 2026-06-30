{
  flake.modules.homeManager.default =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.zsh;
    in
    {

      programs.zsh = {
        syntaxHighlighting.enable = lib.mkDefault true;
        autosuggestion.enable = lib.mkDefault true;
        # historySubstringSearch.enable = true;

        # -C skips compaudit + bypasses dump rebuild (dump is fresh after activation)
        completionInit = ''
          autoload -Uz compinit
          compinit -C -d "$HOME/.zcompdump"

          # Byte-compile the dump for faster loading on subsequent shells
          if [[ -s "$HOME/.zcompdump" && (! -s "$HOME/.zcompdump.zwc" || "$HOME/.zcompdump" -nt "$HOME/.zcompdump.zwc") ]]; then
            zcompile "$HOME/.zcompdump"
          fi
        '';

        initContent =
          lib.mkOrder 550
            # bash
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
      };

      # force rebuild of zcompdump on activation to avoid issues with stale completion data
      home.activation.invalidateZcompdump = lib.mkIf cfg.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD rm -f "$HOME/.zcompdump" "$HOME/.zcompdump.zwc"
        ''
      );

      home.packages = lib.mkIf cfg.enable (
        builtins.attrValues {
          inherit (pkgs)
            fzf
            # tmux
            # eternal-terminal
            ;
        }
      );

      home.shellAliases = {
        l = "ls";
        gr = "cd $(git rev-parse --show-toplevel)";
        sc = "systemctl";
        scu = "systemctl --user";
      };
    };
}
