{
  config =
    let
      padding = 5;
    in
    {
      # default layout (can be bsp, stack or float)
      layout = "bsp";

      # new window spawns to the right if vertical split, or bottom if horizontal split
      window_placement = "second_child";

      # sketchybar
      external_bar = "main:40:0"; # [<main|all|off>:<top_padding>:<bottom_padding>]

      # padding set globally
      top_padding = padding;
      bottom_padding = padding;
      left_padding = padding;
      right_padding = padding;
      window_gap = padding;

      # -- mouse settings --
      mouse_follows_focus = "off";
      focus_follows_mouse = "autoraise";

      # modifier for clicking and dragging with mouse
      mouse_modifier = "alt";
      # set modifier + left-click drag to move window
      mouse_action1 = "move";
      # set modifier + right-click drag to resize window
      mouse_action2 = "resize";
    };
  extraConfig = ''
    # when window is dropped in center of another window, swap them (on edges it will split it)
    yabai -m mouse_drop_action swap
  '';
}
