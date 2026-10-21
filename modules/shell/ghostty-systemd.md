# Ghostty systemd integration on NixOS

## Symptom

`SUPER + RETURN` (and rofi's terminal setting) does nothing until Ghostty has
already been launched once manually, e.g. via rofi.

## Why

The Hyprland bind uses `config.programs.ghostty.openCommand`, which is
`<ghostty> +new-window` when Ghostty's systemd integration is enabled (the
default on Linux, see `modules/shell/ghostty.nix`). `+new-window` does not
start Ghostty: it asks an existing instance, or the systemd/D-Bus unit
`app-com.mitchellh.ghostty.service`, to open a window.

On a cold session the unit is what gets started, and it fails:

```
$ systemctl --user status app-com.mitchellh.ghostty.service
Process: ExecStart=ghostty --gtk-single-instance=true --initial-window=false (status=203/EXEC)
(ghostty)[2640]: app-com.mitchellh.ghostty.service: Unable to locate executable 'ghostty': No such file or directory
```

The unit is installed by the Ghostty package and linked verbatim by
home-manager. Its `ExecStart` is the bare name `ghostty`:

```ini
# ghostty: dist/linux/systemd.service.in
ExecStart=ghostty --gtk-single-instance=true --initial-window=false
```

systemd only searches `$PATH` for a relative `ExecStart=` when `PATH` is set
*in the unit* (`Environment=`, `EnvironmentFile=`, `PassEnvironment=`), or via
`ExecSearchPath=`. The user manager's inherited `PATH` is not used for the
lookup. On an FHS distro the bare name resolves because `/usr/bin` is in
systemd's compiled-in search path; on NixOS the binary is only in
`~/.nix-profile/bin`, so the exec fails before Ghostty ever runs.

Starting Ghostty from rofi works because rofi execs the absolute Nix profile
binary. That process becomes the single instance and owns
`com.mitchellh.ghostty` on the bus, so later `+new-window` calls succeed.

The D-Bus activation file has the same bare executable name:

```ini
# ghostty: dist/linux/dbus.service.in
Exec=ghostty --gtk-single-instance=true --initial-window=false
```

This only matters on a bus that forks `Exec=` itself. The user bus here is
dbus-broker, which delegates activation to systemd through `SystemdService=`
and never uses `Exec=`, so it is not a problem on this setup. It would be a
latent failure under a `dbus-daemon` session without systemd activation.

## Local fix

The home-manager module links the upstream unit by setting
`xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service".source`. We
force that source to a copy with the executable path substituted, so the unit
stays otherwise identical to upstream and no extra drop-in is needed:

```nix
xdg.configFile = lib.mkIf cfg.systemd.enable {
  "systemd/user/app-com.mitchellh.ghostty.service".source = lib.mkForce (
    pkgs.runCommandLocal "ghostty-systemd-user-unit" { } ''
      substitute ${cfg.package}/share/systemd/user/app-com.mitchellh.ghostty.service $out \
        --replace-fail "ExecStart=ghostty" "ExecStart=${lib.getExe cfg.package}"
    ''
  );
};
```

`--replace-fail` makes the build error out if upstream ever renames the line,
instead of silently shipping a broken unit.

Verify with no Ghostty instance running:

```bash
systemctl --user daemon-reload
systemctl --user start app-com.mitchellh.ghostty.service
systemctl --user status app-com.mitchellh.ghostty.service   # active (running), not 203/EXEC
ghostty +new-window
```

If an instance is already running outside systemd, the unit exits cleanly
(`status=0/SUCCESS`) but never sends `READY=1`, so it reports
`Result: protocol`. That is expected and not related to this bug.

## Upstream options

The bare executable name is Ghostty's, not home-manager's. home-manager only
symlinks `${cfg.package}/share/systemd/user/app-com.mitchellh.ghostty.service`,
and nixpkgs does not rewrite that file either.

1. Ghostty: add an `EXEC` template variable and substitute the absolute
   installed path in `dist/linux/systemd.service.in` and
   `dist/linux/dbus.service.in`, via `src/build/GhosttyResources.zig`:

   ```zig
   const Variables = struct {
       NAME: ?[]const u8 = null,
       APPID: ?[]const u8 = null,
       EXEC: ?[]const u8 = null,
   };

   .{ .APPID = app_id, .EXEC = b.getInstallPath(.bin, "ghostty") },
   ```

   Keep `dist/linux/dbus.service.flatpak.in` as bare `ghostty`, since
   `/app/bin` is on PATH inside the Flatpak sandbox. Absolute paths hurt
   relocatability, so maintainers may prefer gating this behind a build
   option.

2. home-manager: substitute the executable path when linking the upstream
   unit (as done locally here), and generate the D-Bus service file with an
   absolute `Exec=` rather than only adding the package to `dbus.packages`.

3. nixpkgs: rewrite both installed files in `postInstall`:

   ```nix
   substituteInPlace $out/share/systemd/user/app-com.mitchellh.ghostty.service \
     --replace-fail "ExecStart=ghostty" "ExecStart=$out/bin/ghostty"
   substituteInPlace $out/share/dbus-1/services/com.mitchellh.ghostty.service \
     --replace-fail "Exec=ghostty" "Exec=$out/bin/ghostty"
   ```

   This does not help this repo, which builds Ghostty from the `ghostty` flake
   overlay rather than nixpkgs.

Once an upstream fix lands, the `lib.mkForce` override in
`modules/shell/ghostty.nix` can be removed.
