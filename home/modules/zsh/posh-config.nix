{ config, ... }:
{
  "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
  blocks = [
    {
      alignment = "left";
      segments = [
        {
          foreground = "p:base0D";
          style = "plain";
          template = "{{ .UserName }}@{{ replaceP `^([^.]+).*$` .HostName `$1` }}";
          type = "session";
        }
        {
          foreground = "p:base0E";
          properties = {
            home_icon = "~";
            style = "folder";
          };
          style = "plain";
          type = "path";
        }
        /*
          {
            foreground = "p:base07";
            properties = {
              branch_icon = " ";
              cherry_pick_icon = " ";
              commit_icon = " ";
              fetch_status = false;
              fetch_upstream_icon = false;
              merge_icon = " ";
              no_commits_icon = " ";
              rebase_icon = " ";
              revert_icon = " ";
              tag_icon = " ";
            };
            style = "plain";
            template = "{{ .HEAD }} ";
            type = "git";
          }
        */
        {
          foreground = "p:base07";
          properties = {
            fetch_status = true;
          };
          style = "plain";
          type = "jujutsu";
        }
        {
          foreground = "p:base05";
          style = "plain";
          template = "";
          type = "text";
        }
      ];
      type = "prompt";
    }
  ];
  transient_prompt = {
    background = "transparent";
    foreground = "p:base05";
    template = " ";
  };
  final_space = true;
  palette = {
    inherit (config.lib.stylix.colors.withHashtag)
      base00
      base01
      base02
      base03
      base04
      base05
      base06
      base07
      base08
      base09
      base0A
      base0B
      base0C
      base0D
      base0E
      base0F
      ;
  };
  version = 2;
}
