{
  "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
  blocks = [
    {
      alignment = "left";
      segments = [
        {
          foreground = "p:blue";
          style = "plain";
          template = "{{ .UserName }}@{{ .HostName }}";
          type = "session";
        }
        {
          foreground = "p:pink";
          properties = {
            home_icon = "~";
            style = "folder";
          };
          style = "plain";
          type = "path";
        }
        {
          foreground = "p:lavender";
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
        {
          foreground = "p:closer";
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
    foreground = "p:closer";
    template = " ";
  };
  final_space = true;
  palette = {
    blue = "#89B4FA";
    closer = "p:os";
    lavender = "#B4BEFE";
    os = "#ACB0BE";
    pink = "#F5C2E7";
  };
  version = 2;
}
