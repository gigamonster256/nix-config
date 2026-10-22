{
  flake.modules.nixos.desktop = {
    # Automatically make the Logitech G533 (USB) or Bluetooth headphones
    # (AirPods, etc.) the default sink when they show up.
    #
    # WirePlumber gives the configured default (default.configured.audio.sink)
    # priority over any other node, so a pure priority rule cannot take over
    # once something has been selected. Instead this hook updates the
    # configured default, exactly like `wpctl set-default` does. WirePlumber
    # remembers the previous default in its preference stack, so when the
    # headset goes away it automatically falls back to whatever was in use
    # before.
    services.pipewire.wireplumber.extraScripts."headset-autoswitch.lua" = ''
      log = Log.open_topic ("s-headset-autoswitch")

      -- Sinks that should become the default when they are plugged in /
      -- connected. Matching is done on the node.name prefix; add more
      -- prefixes here for other devices. To limit the Bluetooth match to one
      -- pair of headphones, use the full name, e.g.
      -- "bluez_output.A4_C6_F0_C6_6B_E1.".
      local preferred_sink_prefixes = {
        "alsa_output.usb-Logitech_G533_Gaming_Headset",
        "bluez_output.",
      }

      local function is_preferred_sink (name)
        for _, prefix in ipairs (preferred_sink_prefixes) do
          if name:sub (1, #prefix) == prefix then
            return true
          end
        end
        return false
      end

      SimpleEventHook {
        name = "headset-autoswitch/prefer-new-sink",
        interests = {
          EventInterest {
            Constraint { "event.type", "=", "session-item-added" },
            Constraint { "event.session-item.interface", "=", "linkable" },
            Constraint { "media.class", "=", "Audio/Sink" },
          },
        },
        execute = function (event)
          local si = event:get_subject ()
          local node = si:get_associated_proxy ("node")
          local name = node and node.properties["node.name"]

          if not name or not is_preferred_sink (name) then
            return
          end

          local api = Plugin.find ("default-nodes-api")
          if not api then
            log:warning ("default-nodes-api plugin not found")
            return
          end

          if api:call ("get-default-configured-node-name", "Audio/Sink") == name then
            return
          end

          if api:call ("set-default-configured-node-name", "Audio/Sink", name) then
            log:info ("switched default sink to " .. name)
          else
            log:warning ("failed to switch default sink to " .. name)
          end
        end
      }:register ()
    '';

    services.pipewire.wireplumber.extraConfig."60-headset-autoswitch" = {
      "wireplumber.components" = [
        {
          name = "headset-autoswitch.lua";
          type = "script/lua";
          provides = "hooks.headset-autoswitch";
        }
      ];
      "wireplumber.profiles" = {
        main = {
          "hooks.headset-autoswitch" = "required";
        };
      };
    };
  };
}
