# hyprland-dotfiles

My Hyprland setup, built from scratch on top of the stock config.

> Work in progress.

## Target system

- Ubuntu 26.04
- Hyprland 0.57 (Lua config: `hyprland.lua`)

## Components

| Role          | Tool          |
| ------------- | ------------- |
| Compositor    | Hyprland      |
| Terminal      | kitty         |
| Bar           | Waybar        |
| Launcher      | hyprlauncher  |
| Lock screen   | hyprlock      |
| Idle daemon   | hypridle      |
| File manager  | Nautilus      |
| Notifications | _TBD_         |

## Install

```sh
git clone git@github.com:ahmdsabbir/hyprland-dotfiles.git ~/hyprland-dotfiles
cd ~/hyprland-dotfiles
./install.sh --dry-run   # preview
./install.sh
```

`install.sh`:

1. Asks which distro you're on (the detected one is preselected) and installs
   anything missing from `packages.<distro>.txt`.
2. Moves any existing file that would block a link to `<file>.bak.<timestamp>`.
3. Symlinks every package into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).
4. Verifies the Hyprland config and reloads Hyprland if it's running.

It is safe to re-run. Options:

| Option          | Effect                                    |
| --------------- | ----------------------------------------- |
| `--dry-run`     | show what would happen, change nothing    |
| `--distro NAME` | `ubuntu`, `arch`, `fedora` or `none`; skips the menu |
| `--no-packages` | same as `--distro none`: only link dotfiles |
| `<pkg> ...`     | link only these packages (e.g. `hypr`)    |

### Supported distros

| Distro | Packages                                                       |
| ------ | -------------------------------------------------------------- |
| Ubuntu | [`packages.ubuntu.txt`](packages.ubuntu.txt), adds `ppa:cppiber/hyprland` if missing |
| Arch   | not yet: install packages yourself, linking still works        |
| Fedora | not yet: install packages yourself, linking still works        |

To add a distro: create `packages.<id>.txt` and an `install_packages_<id>`
function in `install.sh` (and the matching removal in `uninstall.sh`).

Each top-level folder is a Stow package that mirrors `$HOME`. Files are
symlinks into the repo, so editing `~/.config/...` edits the repo. To unlink a
package: `stow -D -t ~ <pkg>`.

New files inside a folder that is linked as a whole (e.g. `~/.config/hypr/modules`,
`~/.config/waybar/themes`) appear immediately. Re-link with
`./install.sh --distro none` after adding:

- a new file or folder directly under `~/.config/<app>/`
- a new script in `bin/.local/bin/` (`~/.local/bin` holds other tools, so each
  script is linked individually)

Every change is recorded in `~/.local/state/hyprland-dotfiles/changes.log`
(packages installed, PPA added, files backed up, folders created).

## Uninstall

```sh
./uninstall.sh --dry-run   # preview
./uninstall.sh
```

Reverts exactly what `install.sh` recorded, newest first:

1. Removes symlinks that point into this repo (nothing else).
2. Moves backed-up files back into place.
3. Removes folders `install.sh` created, if they're empty.
4. Purges the packages it installed and removes the PPA it added
   (apt asks for confirmation). Packages you had before are never touched.

| Option            | Effect                                        |
| ----------------- | --------------------------------------------- |
| `--dry-run`       | show what would happen, change nothing        |
| `--keep-packages` | leave packages and the PPA installed          |
| `--yes`           | don't ask before removing packages            |

If packages are kept, they stay in the log so a later run can remove them.
Without a log (e.g. linked by hand) it only removes the repo symlinks and
restores the newest `<file>.bak.*`.

## Packages

| Package | Links to          |
| ------- | ----------------- |
| `hypr`  | `~/.config/hypr/` |
| `bin`   | `~/.local/bin/`   |
| `waybar`| `~/.config/waybar/` |

## Reloading

`hypr-reload` (also **SUPER + SHIFT + R**) reloads everything:

1. Verifies the Hyprland config; if it has errors, stops and shows them.
2. Reloads Hyprland and checks the running session for errors.
3. Signals Waybar (`USR2`) and kitty (`USR1`) to reload, if running.
4. Restarts hypridle, if running.

Run from a keybind it sends a desktop notification (needs a notification
daemon). Options: `-q` only print errors, `-n` always notify.
`install.sh` runs it at the end.

### Power

`hypr-power logout|reboot|shutdown` asks for confirmation (zenity), then acts.
Clicking Waybar's power icon (far right) opens a dropdown with these three
actions (`waybar/.config/waybar/power-menu.xml`).
`--yes` skips the dialog.

## Hyprland config layout

`hyprland.lua` is only an entry point that `require`s each module:

| Module         | Contents                                         |
| -------------- | ------------------------------------------------ |
| `programs.lua` | terminal, file manager, launcher, main modifier  |
| `monitors.lua` | generic monitor fallback                         |
| `env.lua`      | environment variables                            |
| `autostart.lua`| apps started with Hyprland                       |
| `looks.lua`    | gaps, borders, decoration, animations            |
| `layouts.lua`  | dwindle / master / scrolling                     |
| `misc.lua`     | misc, layers, permissions                        |
| `input.lua`    | keyboard, mouse, touchpad, gestures              |
| `keybinds.lua` | key and mouse bindings                           |
| `rules.lua`    | window and layer rules                           |
| `theme.lua`    | picks the active theme from `themes/`            |
| `host.lua`     | loads `hosts/<hostname>.lua` (last)              |

### Themes

`themes/<name>.lua` holds a palette (`colors`) and shape settings (`look`).
`modules/theme.lua` selects one (`NAME = "light"`), and other modules read it:

```lua
local theme = require("modules.theme")
theme.rgb("border")         -- "rgb(7a7a7a)"
theme.rgba("shadow", 0.6)   -- "rgba(8f8f8f99)"
theme.look.rounding         -- 20
```

| Theme   | Style                                                        |
| ------- | ------------------------------------------------------------ |
| `light` | monotone greys on paper (inspired by "hyprink monotone")     |
| `dark`  | _planned_                                                    |

Waybar reads its palette from `waybar/.config/waybar/themes/<name>.css`
(imported at the top of `style.css`); keep it in sync with the Lua palette.

Performance choices (in `looks.lua` / `misc.lua`): no blur, opaque windows,
shadows off (`look.shadow = true` to enable), short animations, plain
background colour instead of a wallpaper.

### Per-machine settings

`modules/host.lua` loads `hosts/<hostname>.lua` if it exists, after every other
module, so a host file can override anything (monitors, input, gaps...).
Machines without one use the generic config.

To add a machine, create `hypr/.config/hypr/hosts/$(hostname).lua`, e.g.:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = "1.25" })
```

| Host       | Notes                         |
| ---------- | ----------------------------- |
| `sabbirpc` | desktop, two 1080p monitors   |

Check the config without applying it:

```sh
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

## Planned

- [x] Hyprland config split into Lua modules
- [x] Waybar config and style (light)
- [ ] hyprlock / hypridle config
- [x] Light theme (Hyprland)
- [ ] Light theme for kitty, hyprlock, hyprlauncher
- [ ] Dark theme
- [x] Install method (GNU Stow + `install.sh`)
- [x] Per-machine overrides (`hosts/`)
