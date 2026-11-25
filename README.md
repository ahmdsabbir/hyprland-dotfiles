# hyprland-dotfiles

My Hyprland setup: minimal, monotone, easy on the eyes and light on the
machine. Built from scratch on top of the stock config, with a light and a dark
theme that switch everything at once.

> Work in progress.

- **Target:** Ubuntu 26.04, Hyprland 0.57 (Lua config, `hyprland.lua`)
- **Light on resources:** no blur on windows, opaque windows, no shadows, short
  animations, plain background color, event-driven bar modules, no
  always-running launcher daemon.

## Components

| Role            | Tool                                   |
| --------------- | -------------------------------------- |
| Compositor      | Hyprland                               |
| Bar             | Waybar                                 |
| Launcher, menus | rofi (+ qalc calculator, rofimoji)     |
| Terminal        | kitty                                  |
| Notifications   | mako                                   |
| Lock / idle     | hyprlock / hypridle                    |
| Screenshots     | grim + slurp, swappy (annotate), hyprpicker |
| Clipboard       | cliphist + wl-clipboard                |
| Shell prompt    | zsh + oh-my-zsh, custom `yonko` theme  |
| File manager    | Nautilus                               |
| Themes          | `hypr-theme` (light / dark)            |

## Keybindings

`SUPER` is the Windows key.

| Keys | Action |
| --- | --- |
| **Apps** | |
| SUPER + SPACE | app launcher |
| SUPER + Enter | terminal (kitty) |
| SUPER + SHIFT + Enter | drop-down terminal (toggle; keeps its session) |
| SUPER + E | file manager (Nautilus) |
| SUPER + = | calculator |
| SUPER + . | emoji / symbols |
| SUPER + SHIFT + V | clipboard history |
| SUPER + SHIFT + C | color picker (copies the hex code) |
| **Windows** | |
| SUPER + C | close window |
| SUPER + V | toggle floating |
| SUPER + P | pseudo-tile |
| SUPER + J | toggle split direction |
| SUPER + arrows | move focus |
| SUPER + SHIFT + arrows | swap the window with its neighbour (also across monitors) |
| SUPER + Tab | window switcher (all workspaces) |
| SUPER + drag left / right mouse | move (drop on another window to swap) / resize window |
| **Workspaces** | |
| SUPER + 1…0 | go to workspace |
| SUPER + SHIFT + 1…0 | move window to workspace |
| CTRL + ALT + ← / → | previous / next workspace on this monitor (wraps) |
| CTRL + ALT + SHIFT + ← / → | carry the focused window to the previous / next workspace |
| SUPER + scroll | next / previous workspace |
| SUPER + S | show / hide the scratchpad |
| SUPER + ALT + S | move window to the scratchpad |
| **Screenshots** | |
| SUPER + SHIFT + S, or Print | area (drag to select) |
| SHIFT + Print | current monitor |
| CTRL + Print | active window |
| SUPER + Print | screenshot menu (with 3 s / 5 s delays) |
| **Notifications** | |
| SUPER + N | dismiss newest |
| SUPER + SHIFT + N | dismiss all |
| SUPER + CTRL + N | bring back the last one |
| SUPER + ALT + N | do not disturb |
| **System** | |
| SUPER + L | lock screen |
| SUPER + Escape | power menu (lock, log out, restart, shut down) |
| SUPER + M | exit Hyprland |
| SUPER + SHIFT + T | switch light / dark theme |
| SUPER + SHIFT + R | reload all configs |
| Media keys | volume, mic mute, brightness, play / pause / next / previous |

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
2. Removes leftover links to files that were deleted from the repo.
3. Moves any existing file that would block a link to `<file>.bak.<timestamp>`.
4. Symlinks every package into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).
5. Generates the active theme's color files (`hypr-theme apply`).
6. Reloads everything (`hypr-reload`) and reports config errors.

It is safe to re-run, and records every change in
`~/.local/state/hyprland-dotfiles/changes.log` so `uninstall.sh` can undo it.

| Option          | Effect                                               |
| --------------- | ---------------------------------------------------- |
| `--dry-run`     | show what would happen, change nothing               |
| `--distro NAME` | `ubuntu`, `arch`, `fedora` or `none`; skips the menu |
| `--no-packages` | same as `--distro none`: only link dotfiles          |
| `<pkg> ...`     | link only these packages (e.g. `hypr`)               |

| Distro | Packages |
| ------ | -------- |
| Ubuntu | [`packages.ubuntu.txt`](packages.ubuntu.txt); adds `ppa:cppiber/hyprland` if missing |
| Arch   | not yet: install packages yourself, linking still works |
| Fedora | not yet: install packages yourself, linking still works |

To add a distro: create `packages.<id>.txt` and an `install_packages_<id>`
function in `install.sh` (and the matching removal in `uninstall.sh`).

The zsh prompt also needs zsh and oh-my-zsh, which `install.sh` doesn't install.

### Re-linking

Configs are symlinks into the repo, so editing `~/.config/...` edits the repo.
New files inside a folder that is linked as a whole (e.g.
`~/.config/hypr/modules`, `~/.config/hypr/themes`) appear immediately. Run
`./install.sh --distro none` after adding:

- a new file or folder directly under `~/.config/<app>/`
- a new script in `bin/.local/bin/` (`~/.local/bin` holds other tools, so each
  script is linked individually)

## Uninstall

```sh
./uninstall.sh --dry-run   # preview
./uninstall.sh
```

Reverts exactly what `install.sh` recorded, newest first: removes the generated
theme files, removes symlinks that point into this repo (nothing else), moves
backed-up files back, removes folders it created (if empty), and purges the
packages it installed plus the PPA it added (apt asks first). Packages you had
before are never touched.

| Option            | Effect                                   |
| ----------------- | ---------------------------------------- |
| `--dry-run`       | show what would happen, change nothing   |
| `--keep-packages` | leave packages and the PPA installed     |
| `--yes`           | don't ask before removing packages       |

Kept packages stay in the log so a later run can remove them. Without a log
(e.g. linked by hand) it only removes the repo symlinks and restores the newest
`<file>.bak.*`. Not reverted: the GTK color scheme (`gsettings`), which Hyprland
sets at login.

## Waybar

Transparent bar of flat pills, 6 px rounding. Modules react to events or poll
rarely; no custom scripts run in the background.

**Left:** workspace pills, then the tray.

- Workspaces are assigned automatically, **3 per monitor, numbered left to
  right** (one monitor: 1-3; two: 1-3 | 4-6; three: 1-3 | 4-6 | 7-9). Plugging
  a monitor in or out re-assigns them; each bar shows its own monitor's three.
- Shading: the active workspace is the wider, strongest pill; workspaces with
  apps are solid; empty ones are faint.
- The tray shows app icons (Chrome, Slack, Solaar, ...) and hides when empty.

**Right:**

| Pill | Shows | Click | Scroll | Right-click |
| --- | --- | --- | --- | --- |
| Privacy | only while the mic or screen sharing is in use | — | — | — |
| CPU / RAM | `20% 󰻠  32% 󰍛` in one pill; a value's half darkens above 85% / 80% | htop | — | — |
| Media | `󰏤` / `󰐊` while something plays (hover: title); hidden otherwise | play / pause | — | next (middle-click: previous) |
| Volume | `60% 󰕾` | mute | ±5% | mixer (pulsemixer) |
| Mic | `27% 󰍬` | mute | ±5% | mixer (pulsemixer) |
| Network | Wi-Fi name + signal, or 󰈀 on Ethernet | Wi-Fi menu | — | network settings (nmtui) |
| Internet | `󰖟` online, else `limited` / `login` / `offline` (checked every 30 s) | re-check; opens the login page on captive portals | — | — |
| Battery | laptops only | — | — | — |
| Clock | `24/11 10:59` | — | — | — (hover: calendar) |
| Clipboard | `󰅌` | clipboard history | — | — |
| Notifications | `󰂚`, or `󰂛` in do-not-disturb | do not disturb | — | dismiss all (middle-click: show last) |
| Power | `󰐥` | menu: lock, log out, restart, shut down | — | — |

The Wi-Fi menu (`hypr-wifi`) lists nearby networks, strongest first: pick one
to connect (a password is asked only for new secured networks), or disconnect,
rescan, or turn Wi-Fi on/off. The mixer, nmtui and htop open in kitty as
centered floating windows. Log out / restart / shut down ask for confirmation.

## Launcher and menus

rofi, styled after the "hyprink monotone" launcher: a centered 764 px panel
with 80 px rows, big icons, a solid selected row, over a lightly blurred
backdrop. It runs only while open.

- **Apps** (SUPER + SPACE): most-used first; terminal apps open in kitty.
- **Calculator** (SUPER + =, `hypr-calc`, qalc): type, Enter to calculate,
  Enter on the result to copy it. E.g. `2^10`, `15% * 80`, `5 km to mi`,
  `90 min to h`, `100 fahrenheit to celsius`, `50 USD to EUR` (offline rates),
  `now + 3 days`.
- **Emoji / symbols** (SUPER + .): Enter copies.
- **Window switcher** (SUPER + Tab, `hypr-windows`): every window, most recent
  first, with app icons.
- **Clipboard history** (SUPER + SHIFT + V or the Waybar icon,
  `hypr-clipboard`): Enter copies again, Shift + Delete removes an entry,
  `hypr-clipboard --clear` wipes it all.
- **Power menu** (SUPER + Escape, `hypr-power menu`).

## Notifications

mako: top-right pop-ups in the theme's colors (small app name, bold title,
body, icon). Low urgency is faint and leaves after 3 s, normal after 5 s,
critical has a red border and stays. Repeats from the same app are grouped with
a count; at most 4 visible; the last 20 are kept.

Mouse: left-click runs the notification's action, right-click dismisses it,
middle-click dismisses all. Do-not-disturb hides everything except critical
ones. Try it: `notify-send "Hello" "This is a test"`.

## Screenshots

`hypr-screenshot` saves to `~/Pictures/Screenshots` **and** copies to the
clipboard. A notification shows a thumbnail: click it to annotate in swappy
(arrows, boxes, text, blur), or choose "Open". While selecting an area the
screen is frozen, so menus and tooltips stay put; Esc cancels.

From a terminal: `hypr-screenshot area|screen|window|all [--delay N]`.

## Lock screen and idle

hyprlock: flat background, large light-weight clock, date, and a password
field whose border shows what's happening (darker while checking, red on a
wrong password, amber with Caps Lock on). Nothing renders behind it.

hypridle, started with Hyprland:

| After  | Action                               |
| ------ | ------------------------------------ |
| 9 min  | dim backlight (laptops only)         |
| 10 min | lock                                 |
| 11 min | screens off (back on with any input) |

Video playback pauses the timer. Suspend is off by default (commented out in
`hypridle.conf`). `misc.allow_session_lock_restore` lets a new hyprlock take
over if one ever crashes.

## Themes

Two themes, switched as a whole:

| Theme | Look |
| --- | --- |
| **light** | monotone ink on grey paper (inspired by "hyprink monotone"): `#d9d9d9` desktop, `#cccccc` windows, `#3b3b3b` text |
| **dark** | Nord "Polar Night" blue-greys, soft contrast: `#3b4252` desktop, `#2e3440` windows, `#c5ccd8` text, Nord "Aurora" accents |

```sh
hypr-theme toggle      # or SUPER + SHIFT + T
hypr-theme dark        # / light
hypr-theme             # current theme
hypr-theme apply       # re-generate after editing a palette or template
```

All text and terminal colors are checked for contrast (4.5:1 or better), except
deliberately faint placeholders and shell hints.

**One palette per theme is the single source of truth**
(`hypr/.config/hypr/themes/`):

| File | What |
| --- | --- |
| `<name>.colors` | the palette: UI colors, status colors, 16 terminal colors, GTK color scheme |
| `<name>.lua` | look: gaps, rounding, blur, dim |
| `templates/*` | per-app color files with `{{key}}` slots |
| `light.kitty-extra` | light-only 256-color fixes for kitty |

Hyprland reads the palette directly. For everything else `hypr-theme` renders
the templates into the apps' config folders (outside the repo), which their
configs include:

| App | Generated file | Included by |
| --- | --- | --- |
| kitty | `~/.config/kitty/theme.conf` | `kitty.conf` |
| Waybar | `~/.config/waybar/theme.css` | `style.css` |
| rofi | `~/.config/rofi/theme.rasi` | `layout.rasi` |
| hyprlock | `~/.config/hypr/hyprlock-theme.conf` | `hyprlock.conf` |
| mako | `~/.config/mako/theme` | `config` (last line) |
| GTK 4 | `~/.config/gtk-4.0/gtk.css` | GTK (both themes, chosen by color scheme) |

Switching saves the choice in `~/.local/state/hyprland-dotfiles/theme`, sets the
GTK color scheme (GTK apps, browsers and Electron apps that follow the system
switch too; the GNOME session shares this setting), and reloads Hyprland,
Waybar, kitty and mako live. rofi and hyprlock pick it up next time they open;
the zsh prompt follows kitty. Rendering is all-or-nothing: a bad template
changes nothing. GTK 3 apps use stock Adwaita (light or dark).

To add a theme: copy `light.colors` / `light.lua` to `<name>.*`, edit, then
`hypr-theme <name>`.

## Shell prompt

`zsh/.oh-my-zsh/custom/themes/yonko.zsh-theme`, selected by `ZSH_THEME="yonko"`
in `~/.zshrc` (`.zshrc` itself isn't managed here). Minimal and adaptive: one
line normally, two inside a git repo so branch info never crowds what you type.

```
~ ❯
~/Downloads ❯

hyprland-dotfiles on ⎇ main ⇡1 !1 ?1
❯

hyprland-dotfiles/hypr on ⎇ main !1
✗ 1 ❯                                         took 12s
```

Uses only the terminal's 16 theme colors, so it follows the theme: bold folder,
green branch and success arrow, faint details, red for a failed command or
conflicts, yellow while rebasing or merging. Git: `⇡`/`⇣` ahead/behind, `+`
staged, `!` modified, `?` untracked, `=` conflicts, `≡` stashes. Also when
relevant: `via 󰌠 venv`, background jobs `✦1`, `user@host` over SSH, `root`,
and `took Ns` for commands over 2 s.

## Repository layout

Each top-level folder is a Stow package that mirrors `$HOME`:

| Package  | Links to                       | Contents |
| -------- | ------------------------------ | -------- |
| `hypr`   | `~/.config/hypr/`              | Hyprland (Lua), themes, hyprlock, hypridle |
| `bin`    | `~/.local/bin/`                | `hypr-*` helper scripts |
| `waybar` | `~/.config/waybar/`            | bar layout, style, power menu |
| `kitty`  | `~/.config/kitty/`             | terminal |
| `rofi`   | `~/.config/rofi/`              | launcher layout |
| `mako`   | `~/.config/mako/`              | notifications |
| `zsh`    | `~/.oh-my-zsh/custom/themes/`  | prompt theme |

### Scripts (`bin/.local/bin/`)

| Script | Does |
| --- | --- |
| `hypr-reload` | verify + reload Hyprland, Waybar, kitty, mako, hypridle (`-q` quiet, `-n` notify) |
| `hypr-theme` | switch / re-generate themes |
| `hypr-power` | lock, log out, restart, shut down, or `menu` |
| `hypr-screenshot` | screenshots (area, screen, window, all, menu) |
| `hypr-clipboard` | clipboard history menu |
| `hypr-calc` | calculator menu |
| `hypr-windows` | window switcher |
| `hypr-wifi` | Wi-Fi menu |
| `hypr-internet` | internet status for Waybar |
| `hypr-notify` | notification controls (do-not-disturb, dismiss, restore) |
| `hypr-dropdown` | drop-down terminal toggle |

### Hyprland config

`hyprland.lua` is only an entry point that loads each module:

| Module | Contents |
| --- | --- |
| `programs.lua` | terminal, file manager, launcher, main modifier |
| `monitors.lua` | generic monitor fallback |
| `env.lua` | environment variables |
| `autostart.lua` | Waybar, hypridle, clipboard recorder, GTK color scheme |
| `looks.lua` | gaps, borders, decoration, blur, animations (from the theme) |
| `layouts.lua` | dwindle / master / scrolling |
| `workspaces.lua` | 3 workspaces per monitor, left to right |
| `misc.lua` | background, layers, permissions |
| `input.lua` | keyboard, mouse, touchpad, gestures |
| `keybinds.lua` | key and mouse bindings |
| `rules.lua` | window and layer rules (floating tools, launcher blur) |
| `theme.lua` | active theme: palette + look |
| `host.lua` | loads `hosts/<hostname>.lua` (last) |

Check the config without applying it:

```sh
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

### Per-machine settings

`hosts/<hostname>.lua` is loaded after every other module, so it can override
anything (monitors, input, gaps...). Machines without one use the generic
config. To add a machine, create `hypr/.config/hypr/hosts/$(hostname).lua`, e.g.:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = "1.25" })
```

| Host       | Notes |
| ---------- | ----- |
| `sabbirpc` | desktop, two 1080p monitors (Mi left, Redmi right) |

## Status

Done:

- [x] Hyprland config in Lua modules, per-machine overrides
- [x] Install / uninstall scripts (GNU Stow, change log, distro menu)
- [x] Waybar, rofi launcher + menus, kitty, mako, hyprlock / hypridle
- [x] Screenshots, clipboard history, color picker
- [x] GTK apps
- [x] Light and dark themes, `hypr-theme` switcher
- [x] zsh prompt

Not yet:

- [ ] Package lists for Arch and Fedora
- [ ] Managing `~/.zshrc` (and installing oh-my-zsh + plugins)
