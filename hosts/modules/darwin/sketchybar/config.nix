{
  lib,
  pkgs,
  config,
}:
lib.concatStrings [
  ''
    PLUGIN_DIR="${pkgs.sketchybar-plugins.all}"

    sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000

    default=(
      padding_left=5
      padding_right=5
      icon.font="JetBrainsMono NF:Bold:17.0"
      label.font="JetBrainsMono NF:Bold:14.0"
      icon.color=0xffffffff
      label.color=0xffffffff
      icon.padding_left=4
      icon.padding_right=4
      label.padding_left=4
      label.padding_right=4
    )
    sketchybar --default "''${default[@]}"

    ##### Adding Left Items #####
    # We add some regular items to the left side of the bar, where
    # only the properties deviating from the current defaults need to be set
  ''
  (
    if config.services.aerospace.enable then
      ''
        sketchybar --add event aerospace_workspace_change

        for sid in $(aerospace list-workspaces --all); do
            sketchybar --add item space.$sid left \
                --subscribe space.$sid aerospace_workspace_change \
                --set space.$sid \
                background.color=0x40ffffff \
                background.corner_radius=5 \
                background.height=25 \
                background.drawing=off \
                icon="$sid" \
                icon.padding_left=7 \
                icon.padding_right=7 \
                label.drawing=off \
                click_script="aerospace workspace $sid" \
                script="$PLUGIN_DIR/aerospace.sh $sid"
        done

      ''
    else
      ''
        SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
        for i in "''${!SPACE_ICONS[@]}"
        do
          sid="$(($i+1))"
          space=(
            space="$sid"
            icon="''${SPACE_ICONS[i]}"
            icon.padding_left=7
            icon.padding_right=7
            background.color=0x40ffffff
            background.corner_radius=5
            background.height=25
            label.drawing=off
            script="$PLUGIN_DIR/builtin/space.sh"
            click_script="yabai -m space --focus $sid"
          )
          sketchybar --add space space."$sid" left --set space."$sid" "''${space[@]}"
        done
      ''
  )
  ''
    sketchybar --add item chevron left \
               --set chevron icon= label.drawing=off \
               --add item front_app left \
               --set front_app icon.drawing=off script="$PLUGIN_DIR/builtin/front_app.sh" \
               --subscribe front_app front_app_switched

    ##### Adding Right Items #####
    # In the same way as the left items we can add items to the right side.
    # Additional position (e.g. center) are available, see:
    # https://felixkratz.github.io/SketchyBar/config/items#adding-items-to-sketchybar

    # Some items refresh on a fixed cycle, e.g. the clock runs its script once
    # every 10s. Other items respond to events they subscribe to, e.g. the
    # volume.sh script is only executed once an actual change in system audio
    # volume is registered. More info about the event system can be found here:
    # https://felixkratz.github.io/SketchyBar/config/events

    sketchybar --add item clock right \
               --set clock update_freq=10 icon=  script="$PLUGIN_DIR/builtin/clock.sh" \
               --add item volume right \
               --set volume script="$PLUGIN_DIR/builtin/volume.sh" \
               --subscribe volume volume_change \
               --add item battery right \
               --set battery update_freq=120 script="$PLUGIN_DIR/builtin/battery.sh" \
               --subscribe battery system_woke power_source_change
    sketchybar --update
  ''
]
