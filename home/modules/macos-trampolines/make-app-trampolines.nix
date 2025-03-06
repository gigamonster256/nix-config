# Credit: https://github.com/nix-community/home-manager/issues/1341
# could be improved upon...
''
  fromDir="$HOME/Applications/Home Manager Apps"
  toDir="$HOME/Applications/Home Manager Trampolines"
  mkdir -p "$toDir"

  (
    cd "$fromDir"
    for app in *.app; do
      /usr/bin/osacompile -o "$toDir/$app" -e "do shell script \"open '$fromDir/$app'\""

      # copy icon
      icon="$(/usr/bin/plutil -extract CFBundleIconFile raw "$fromDir/$app/Contents/Info.plist")"
      # append .icns if it's not already there
      if [[ $icon != *".icns" ]]; then
        icon="$icon.icns"
      fi
      mkdir -p "$toDir/$app/Contents/Resources"
      cp -f "$fromDir/$app/Contents/Resources/$icon" "$toDir/$app/Contents/Resources/applet.icns"
    done
  )

  # cleanup
  (
    cd "$toDir"
    for app in *.app; do
      if [ ! -d "$fromDir/$app" ]; then
        rm -rf "$toDir/$app"
      fi
    done
  )
''
