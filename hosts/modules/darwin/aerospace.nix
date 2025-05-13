{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    toLower
    lists
    listToAttrs
    ;
  inherit (config.services) sketchybar;
in
{
  services.aerospace.settings = {
    gaps.outer = mkIf sketchybar.enable {
      top = 40; # sketchybar height
    };
    # Notify Sketchybar about workspace change
    exec-on-workspace-change = mkIf sketchybar.enable [
      "${getExe pkgs.bash}"
      "-c"
      "${getExe sketchybar.package} --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
    ];

    mode.main.binding =
      let
        workspaces = lists.map toString (lists.range 1 9); # ++ ["A"];
        forAllWorkspaces =
          keyfn: actionfn:
          builtins.listToAttrs (
            lists.map (ws: {
              name = keyfn ws;
              value = actionfn ws;
            }) workspaces
          );
        focusWorkspaces = forAllWorkspaces (ws: "alt-${toLower ws}") (ws: "workspace ${ws}");
        moveToWorkspace = forAllWorkspaces (ws: "alt-shift-${toLower ws}") (
          ws: "move-node-to-workspace ${ws}"
        );
      in
      focusWorkspaces // moveToWorkspace;

    workspace-to-monitor-force-assignment =
      let
        workspaces = lists.range 1 9;
        assignment =
          ws:
          if ws <= 5 then
            "main"
          else
            [
              "secondary"
              "main"
            ];
      in
      listToAttrs (
        lists.map (ws: {
          name = builtins.toString ws;
          value = assignment ws;
        }) workspaces
      );
  };
}
