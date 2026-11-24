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
| Launcher      | rofi          |
| Lock screen   | hyprlock      |
| Idle daemon   | hypridle      |
| File manager  | Nautilus      |
| Notifications | mako          |

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
| `kitty` | `~/.config/kitty/`  |
| `rofi`  | `~/.config/rofi/`   |
| `mako`  | `~/.config/mako/`   |
| `zsh`   | `~/.oh-my-zsh/custom/themes/` (prompt theme; needs zsh + oh-my-zsh) |

## Reloading

`hypr-reload` (also **SUPER + SHIFT + R**) reloads everything:

1. Verifies the Hyprland config; if it has errors, stops and shows them.
2. Reloads Hyprland and checks the running session for errors.
3. Signals Waybar (`USR2`) and kitty (`USR1`) to reload, if running.
4. Restarts hypridle, if running.

Run from a keybind it sends a desktop notification (needs a notification
daemon). Options: `-q` only print errors, `-n` always notify.
`install.sh` runs it at the end.

### Bar controls

Workspace pills are shaded by state: the active one is dark and wider,
workspaces with apps are grey, empty ones are faint.
Workspaces are assigned automatically (`modules/workspaces.lua`): 3 per
connected monitor, numbered left to right (one monitor: 1-3; two: 1-3 | 4-6;
three: 1-3 | 4-6 | 7-9). Plugging a monitor in or out re-assigns them. Each bar
shows its own monitor's three.

| Pill    | Shows                  | Click            | Scroll       | Right-click            |
| ------- | ---------------------- | ---------------- | ------------ | ---------------------- |
| Volume  | `60% 󰕾`                | mute             | volume ±5%   | mixer (pulsemixer)     |
| Mic     | `27% 󰍬`                | mute             | mic ±5%      | mixer (pulsemixer)     |
| Network | Wi-Fi name + signal, or 󰈀 | Wi-Fi menu (`hypr-wifi`) | — | settings (nmtui)   |
| Internet | `󰖟` online; `limited` / `login` / `offline` otherwise (checked every 30 s, `hypr-internet`) | re-check; opens the login page on captive portals | — | — |
| CPU / RAM | `15% 󰻠` `64% 󰍛`; pill darkens above 85% / 80% | htop | — | — |
| Privacy | only while mic / screen share is in use | — | — | — |
| Tray    | app tray icons (Slack, Solaar, ...); hidden when empty | app menu | — | app menu |
| Clipboard | `󰅌` | clipboard history (Enter copies, Shift+Delete removes) | — | — |

`hypr-wifi` lists nearby networks (strongest first): pick one to connect
(password asked only for new secured networks; saved ones reconnect), or
disconnect, rescan, turn Wi-Fi on/off. The mixer and nmtui open in kitty as
centered floating windows.

### Power

`hypr-power logout|reboot|shutdown` asks for confirmation (zenity), then acts.
Clicking Waybar's power icon (far right) opens a dropdown with these three
actions (`waybar/.config/waybar/power-menu.xml`).
`--yes` skips the dialog.

## Launcher

rofi (`rofi/.config/rofi/`, layout in `layout.rasi`, colors from the theme). It runs only while
open, so it uses no memory in the background.

| Keys              | Opens                                                    |
| ----------------- | -------------------------------------------------------- |
| SUPER + R         | apps, most-used first; terminal apps open in kitty       |
| SUPER + =         | calculator (`hypr-calc`, qalc): Enter calculates, Enter on the result copies it |
| SUPER + .         | emoji / symbols (rofimoji): Enter copies                 |
| SUPER + Tab       | window switcher, all workspaces (`hypr-windows`)         |
| SUPER + SHIFT + V | clipboard history (`hypr-clipboard`): Enter copies, Shift+Delete removes, `--clear` wipes it |
| SUPER + Escape    | power menu (`hypr-power menu`)                           |

Calculator examples: `2^10`, `15% * 80`, `5 km to mi`, `90 min to h`,
`100 fahrenheit to celsius`, `50 USD to EUR` (offline exchange rates),
`now + 3 days`.

## Notifications

mako (`mako/.config/mako/config`): top-right pop-ups in the light palette,
small app name + bold title + body, icons on the left. Low urgency is faint
and leaves after 3 s, normal after 5 s, critical has a red border and stays.
Repeats from the same app/title are grouped with a count; at most 4 visible.

| Action                    | Mouse / bar                 | Keys            |
| ------------------------- | --------------------------- | --------------- |
| run the notification's action | left-click it           |                 |
| dismiss                   | right-click it              | SUPER + N       |
| dismiss all               | middle-click it, or right-click the bell | SUPER + SHIFT + N |
| bring back the last one   | middle-click the bell       | SUPER + CTRL + N |
| do not disturb            | click the bell (󰂚 / 󰂛)      | SUPER + ALT + N |

Do-not-disturb hides everything except critical notifications. History keeps
the last 20. Try it: `notify-send "Hello" "This is a test"`.

## GTK apps

- **Color scheme:** each palette's `color_scheme` is applied by `hypr-theme`
  (and at login). GTK/libadwaita apps switch instantly; browsers and Electron
  apps set to follow the system do too. The GNOME session shares this setting.
- **libadwaita colors** (Nautilus, zenity, GNOME apps): generated
  `~/.config/gtk-4.0/gtk.css` holds both themes, each inside
  `@media (prefers-color-scheme: …)`, so open apps follow a switch.
- **GTK 3 apps** use stock Adwaita (light or dark).

## Screenshots

`hypr-screenshot` saves to `~/Pictures/Screenshots` **and** copies to the
clipboard. A notification shows a thumbnail: click it to annotate (swappy:
arrows, boxes, text, blur), or choose "Open".

| Keys              | Captures                                             |
| ----------------- | ---------------------------------------------------- |
| SUPER + SHIFT + S or Print | an area: drag to select (screen frozen meanwhile, Esc cancels) |
| SHIFT + Print     | the current monitor                                  |
| CTRL + Print      | the active window                                    |
| SUPER + Print     | menu: area / window / screen / all, plus 3 s and 5 s delays |
| SUPER + SHIFT + C | color picker: click a pixel, its hex code is copied  |

Also from a terminal: `hypr-screenshot area|screen|window|all [--delay N]`.

## Lock screen and idle

hyprlock (`hyprlock.conf`): flat background, large light clock, date,
password field (border turns dark while checking, red on a wrong password,
amber with Caps Lock on). Nothing renders behind it while you're away.

Lock with **SUPER + L**, the Waybar power menu, or SUPER + Escape → Lock.

hypridle (`hypridle.conf`), started with Hyprland:

| After  | Action                               |
| ------ | ------------------------------------ |
| 9 min  | dim backlight (laptops only)         |
| 10 min | lock                                 |
| 11 min | screens off (back on with any input) |

Apps that inhibit idle (video playback) pause the timer. Suspend is off by
default (commented out). `misc.allow_session_lock_restore` lets a new
hyprlock take over if one ever crashes.

## Shell prompt

`zsh/.oh-my-zsh/custom/themes/yonko.zsh-theme`, selected by `ZSH_THEME="yonko"`
in `~/.zshrc` (not managed here). Minimal and adaptive: one line normally, two
lines inside a git repo so branch info never crowds what you type.

```
~ ❯
~/Downloads ❯

hyprland-dotfiles on ⎇ main ⇡1 !1 ?1
❯

hyprland-dotfiles/hypr on ⎇ main !1
✗ 1 ❯                                         took 12s
```

Ink + one green accent, using only the terminal's 16 theme colors (follows the
kitty theme): bold folder, green branch and success arrow, faint details, red
for a failed command / conflicts, yellow while rebasing or merging.
Git: `⇡`/`⇣` ahead/behind, `+` staged, `!` modified, `?` untracked,
`=` conflicts, `≡` stashes. Also when relevant: `via 󰌠 venv`, background jobs
`✦1`, `user@host` over SSH, `root`. `took Ns` for commands over 2 s.

Needs zsh and oh-my-zsh on the machine (not installed by `install.sh`).

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
| `workspaces.lua` | 3 workspaces per monitor, left to right        |
| `misc.lua`     | misc, layers, permissions                        |
| `input.lua`    | keyboard, mouse, touchpad, gestures              |
| `keybinds.lua` | key and mouse bindings                           |
| `rules.lua`    | window and layer rules                           |
| `theme.lua`    | active theme: palette + look (see Themes)        |
| `host.lua`     | loads `hosts/<hostname>.lua` (last)              |

### Themes

Two themes, **light** and **dark**, switched as a whole:

```sh
hypr-theme toggle      # or SUPER + SHIFT + T
hypr-theme dark        # / light
hypr-theme             # current theme
hypr-theme apply       # re-generate after editing a palette or template
```

One palette per theme is the single source of truth:

| File | What |
| --- | --- |
| `themes/<name>.colors` | **the palette**: UI colors, status inks, 16 terminal colors, GTK color scheme |
| `themes/<name>.lua` | look: gaps, rounding, blur, dim |
| `themes/templates/*` | per-app color files with `{{key}}` slots |
| `themes/light.kitty-extra` | light-only 256-color fixes for kitty |

Hyprland reads the palette directly (`modules/theme.lua`). For everything else
`hypr-theme` renders the templates into the apps' config folders (outside the
repo), which their configs include:

| App | Generated file | Included by |
| --- | --- | --- |
| kitty | `~/.config/kitty/theme.conf` | `kitty.conf` |
| Waybar | `~/.config/waybar/theme.css` | `style.css` |
| rofi | `~/.config/rofi/theme.rasi` | `layout.rasi` |
| hyprlock | `~/.config/hypr/hyprlock-theme.conf` | `hyprlock.conf` |
| mako | `~/.config/mako/theme` | `config` (last line) |
| GTK 4 | `~/.config/gtk-4.0/gtk.css` | GTK (both themes, by color scheme) |

Switching writes the choice to `~/.local/state/hyprland-dotfiles/theme`, sets
the GTK color scheme, and reloads Hyprland, Waybar, kitty and mako live; rofi
and hyprlock pick it up next time they open; the zsh prompt follows kitty.
Rendering is all-or-nothing: a bad template changes nothing. `install.sh`
generates the files; `uninstall.sh` removes them.

To add a theme: copy `light.colors` / `light.lua` to `<name>.*`, edit, then
`hypr-theme <name>`.

Performance choices (in `looks.lua` / `misc.lua`): no blur on windows, opaque
windows, shadows off, short animations, plain background color.

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
- [x] hyprlock / hypridle config (light)
- [x] Light theme (Hyprland)
- [x] Light theme for kitty
- [x] Launcher (rofi) with light theme, calculator, emoji, window switcher, clipboard history
- [x] GTK apps
- [x] Dark theme + theme switcher (`hypr-theme`)
- [x] Install method (GNU Stow + `install.sh`)
- [x] Per-machine overrides (`hosts/`)
