{
  flake.modules.darwin.base =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) lists;
      inherit (config.services) sketchybar;
    in
    {
      services.aerospace.settings = {
        gaps.outer = lib.mkIf sketchybar.enable {
          top = 40; # sketchybar height
        };
        # Notify Sketchybar about workspace change
        exec-on-workspace-change = lib.mkIf sketchybar.enable [
          "${lib.getExe pkgs.bash}"
          "-c"
          "${lib.getExe sketchybar.package} --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
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
            focusWorkspaces = forAllWorkspaces (ws: "alt-${lib.toLower ws}") (ws: "workspace ${ws}");
            moveToWorkspace = forAllWorkspaces (ws: "alt-shift-${lib.toLower ws}") (
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
          lib.listToAttrs (
            lists.map (ws: {
              name = builtins.toString ws;
              value = assignment ws;
            }) workspaces
          );
      };
    };
}
