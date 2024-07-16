{
  config = {
    # default layout (can be bsp, stack or float)
    layout = "bsp";

    # new window spawns to the right if vertical split, or bottom if horizontal split
    window_placement = "second_child";

    # padding set to 10px
    top_padding = 50; # 50px for sketchybar
    bottom_padding = 10;
    left_padding = 10;
    right_padding = 10;
    window_gap = 8;

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
