#!/usr/bin/env bash
# Install packages and symlink these dotfiles into $HOME with GNU Stow.
#
# Usage: ./install.sh [--dry-run] [--distro NAME] [--no-packages] [package ...]
#
#   --dry-run       Show what would happen, change nothing.
#   --distro NAME   ubuntu | arch | fedora | none. Skips the distro menu.
#   --no-packages   Same as --distro none: only link dotfiles.
#   package ...     Stow only these packages (default: every top-level folder).
#
# Safe to re-run. Existing files that would block a link are moved to
# <file>.bak.<timestamp>, never deleted. Every change is recorded in
# ~/.local/state/hyprland-dotfiles/changes.log so ./uninstall.sh can undo it.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-dotfiles"
STATE_LOG="$STATE_DIR/changes.log"

# Distro menu: id, label. A distro is supported once it has
# packages.<id>.txt and an install_packages_<id> function below.
DISTRO_IDS=(ubuntu arch fedora)
DISTRO_LABELS=("Ubuntu" "Arch Linux" "Fedora")

DRY_RUN=0
DISTRO=""
STOW_PACKAGES=()

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Run a command, or just print it in dry-run mode.
run() {
    if (( DRY_RUN )); then
        printf '   [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# Record a change for uninstall.sh: one tab-separated line per change.
#   ppa    <ppa>             apt repository added
#   apt    <package>         package installed
#   backup <target> <backup> existing file moved aside
#   mkdir  <dir>             directory created
#   link   <stow-package>    package symlinked
record() {
    (( DRY_RUN )) && return 0
    mkdir -p "$STATE_DIR"
    local IFS=$'\t'
    printf '%s\n' "$*" >> "$STATE_LOG"
}

usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
    case "$1" in
        --dry-run)     DRY_RUN=1 ;;
        --distro)      [[ $# -ge 2 ]] || die "--distro needs a value"; DISTRO="$2"; shift ;;
        --distro=*)    DISTRO="${1#*=}" ;;
        --no-packages) DISTRO="none" ;;
        -h|--help)     usage; exit 0 ;;
        -*)            die "Unknown option: $1 (see --help)" ;;
        *)             STOW_PACKAGES+=("${1%/}") ;;
    esac
    shift
done

(( EUID != 0 )) || die "Run as your normal user, not root. sudo is used where needed."

# ---------------------------------------------------------------------------
# Distro selection
# ---------------------------------------------------------------------------

is_supported() { declare -F "install_packages_$1" >/dev/null && [[ -f "$REPO/packages.$1.txt" ]]; }

# Best guess from /etc/os-release; empty if unknown.
detect_distro() {
    local id="" like=""
    if [[ -r /etc/os-release ]]; then
        id="$(. /etc/os-release; echo "${ID:-}")"
        like="$(. /etc/os-release; echo "${ID_LIKE:-}")"
    fi
    case " $id $like " in
        *" ubuntu "*) echo ubuntu ;;
        *" arch "*)   echo arch ;;
        *" fedora "*) echo fedora ;;
    esac
}

choose_distro() {
    local detected i choice default=$(( ${#DISTRO_IDS[@]} + 1 ))
    detected="$(detect_distro)"

    if [[ -n "$DISTRO" ]]; then
        [[ "$DISTRO" == none || " ${DISTRO_IDS[*]} " == *" $DISTRO "* ]] \
            || die "Unknown distro: $DISTRO (choose: ${DISTRO_IDS[*]} none)"
    elif [[ ! -t 0 ]]; then
        # No terminal to ask: use the detected distro, else skip packages.
        DISTRO="${detected:-none}"
        log "No terminal for the menu; using distro: $DISTRO"
    else
        echo
        echo "Which distro is this? (installs packages for it)"
        for i in "${!DISTRO_IDS[@]}"; do
            local id="${DISTRO_IDS[$i]}" note=""
            is_supported "$id" || note="  (not supported yet)"
            [[ "$id" == "$detected" ]] && { note="$note  <- detected"; default=$((i + 1)); }
            printf '  %d) %s%s\n' $((i + 1)) "${DISTRO_LABELS[$i]}" "$note"
        done
        printf '  %d) None: skip packages, only link dotfiles\n' $(( ${#DISTRO_IDS[@]} + 1 ))
        while :; do
            read -r -p "Choose [${default}]: " choice
            choice="${choice:-$default}"
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#DISTRO_IDS[@]} + 1 )); then
                break
            fi
            echo "Enter a number from 1 to $(( ${#DISTRO_IDS[@]} + 1 ))."
        done
        if (( choice <= ${#DISTRO_IDS[@]} )); then
            DISTRO="${DISTRO_IDS[$((choice - 1))]}"
        else
            DISTRO="none"
        fi
        echo
    fi

    if [[ "$DISTRO" != none && -n "$detected" && "$DISTRO" != "$detected" ]]; then
        warn "You chose $DISTRO, but this looks like $detected."
    fi
}

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------

# Read packages.<distro>.txt into the array named by $2.
read_package_list() {
    local -n _out="$2"
    local pkg
    while IFS= read -r pkg; do
        pkg="${pkg%%#*}"; pkg="${pkg//[[:space:]]/}"
        [[ -n "$pkg" ]] && _out+=("$pkg")
    done < "$REPO/packages.$1.txt"
}

install_packages_ubuntu() {
    local ppa="ppa:cppiber/hyprland" ppa_match="cppiber/hyprland"
    command -v apt-get >/dev/null || die "apt-get not found. Is this really Ubuntu? Re-run with --distro none to skip packages."

    local wanted=() missing=() pkg
    read_package_list ubuntu wanted

    for pkg in "${wanted[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" \
            || missing+=("$pkg")
    done

    if (( ${#missing[@]} == 0 )); then
        log "All ${#wanted[@]} packages already installed."
        return
    fi
    log "Missing packages: ${missing[*]}"

    # Hyprland on Ubuntu comes from a PPA.
    if ! grep -rqs "$ppa_match" /etc/apt/sources.list /etc/apt/sources.list.d/; then
        log "Adding $ppa"
        if ! command -v add-apt-repository >/dev/null; then
            run sudo apt-get install -y software-properties-common
            record apt software-properties-common
        fi
        run sudo add-apt-repository -y "$ppa"
        record ppa "$ppa"
    fi

    run sudo apt-get update
    run sudo apt-get install -y "${missing[@]}"
    for pkg in "${missing[@]}"; do
        record apt "$pkg"
    done
}

install_packages() {
    [[ "$DISTRO" == none ]] && { log "Skipping packages."; return; }
    if ! is_supported "$DISTRO"; then
        warn "$DISTRO isn't supported yet: skipping packages."
        warn "Install the packages listed in packages.ubuntu.txt (names may differ) yourself."
        return
    fi
    log "Installing packages for: $DISTRO"
    "install_packages_$DISTRO"
}

# ---------------------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------------------

PENDING=0

# Move aside any real file (or foreign symlink) where a package wants a link.
backup_conflicts() {
    local pkg="$1" src rel target
    while IFS= read -r -d '' src; do
        rel="${src#"$REPO/$pkg/"}"
        target="$HOME/$rel"

        # Nothing there, or already resolves to this repo file: fine.
        [[ -e "$target" || -L "$target" ]] || continue
        [[ "$(readlink -f "$target")" == "$(readlink -f "$src")" ]] && continue

        warn "Backing up $target -> $target.bak.$TS"
        run mv "$target" "$target.bak.$TS"
        record backup "$target" "$target.bak.$TS"
        PENDING=$((PENDING + 1))
    done < <(find "$REPO/$pkg" \( -type f -o -type l \) -print0)
}

# Create the first two directory levels (e.g. ~/.config and ~/.config/hypr) as
# real directories. Otherwise Stow may "fold" them into a single symlink, and
# on a fresh machine all of ~/.config would point into this repo.
# Deeper folders (e.g. hypr/modules) are still folded, so new files appear
# without re-running.
make_parent_dirs() {
    local pkg="$1" dir
    while IFS= read -r -d '' dir; do
        dir="$HOME/${dir#"$REPO/$pkg/"}"
        [[ -d "$dir" ]] && continue
        run mkdir -p "$dir"
        record mkdir "$dir"
        PENDING=$((PENDING + 1))
    done < <(find "$REPO/$pkg" -mindepth 1 -maxdepth 2 -type d -print0)
}

# Remove dangling symlinks that point into this repo (files deleted or moved
# in the repo since the last install), so they don't linger in $HOME.
prune_stale_links() {
    local repo_real link target
    repo_real="$(cd "$REPO" && pwd -P)"
    while IFS= read -r -d '' link; do
        target="$(readlink -m "$link")"
        [[ "$target" == "$repo_real/"* ]] || continue
        log "Removing stale link ${link/#$HOME/\~}"
        run rm "$link"
    done < <(find "$HOME/.config" -maxdepth 3 -xtype l -print0 2>/dev/null
             find "$HOME/.local/bin" -maxdepth 1 -xtype l -print0 2>/dev/null
             find "$HOME/.oh-my-zsh/custom" -maxdepth 2 -xtype l -print0 2>/dev/null)
}

# Render the active theme's colors for kitty, Waybar, rofi, hyprlock, mako and
# GTK (files the linked configs include). Uses the repo copy of the themes, so
# it works on the first install too.
generate_theme() {
    local theme="$REPO/bin/.local/bin/hypr-theme"
    [[ -x "$theme" && -d "$REPO/hypr/.config/hypr/themes" ]] || return 0
    # GTK reads its colors from ~/.config/gtk-4.0/gtk.css; no package creates
    # that folder, so make it (recorded, so uninstall removes it again).
    local gtk_dir="$HOME/.config/gtk-4.0"
    if [[ ! -d "$gtk_dir" ]]; then
        run mkdir -p "$gtk_dir"
        record mkdir "$gtk_dir"
    fi
    if (( DRY_RUN )); then
        printf '   [dry-run] hypr-theme apply --no-reload (generate theme colors)\n'
        return 0
    fi
    HYPR_THEMES_DIR="$REPO/hypr/.config/hypr/themes" "$theme" apply --no-reload \
        && log "Theme: $("$theme")" || warn "Generating theme colors failed (run: hypr-theme apply)"
}

link_dotfiles() {
    local have_stow=1
    command -v stow >/dev/null || have_stow=0
    (( have_stow || DRY_RUN )) \
        || die "stow is not installed. Install it with your package manager, then re-run."

    if (( ${#STOW_PACKAGES[@]} == 0 )); then
        local d
        for d in "$REPO"/*/; do
            STOW_PACKAGES+=("$(basename "$d")")
        done
    fi

    prune_stale_links

    local pkg
    for pkg in "${STOW_PACKAGES[@]}"; do
        [[ -d "$REPO/$pkg" ]] || die "No such package: $pkg"
        backup_conflicts "$pkg"
        make_parent_dirs "$pkg"
    done

    log "Linking: ${STOW_PACKAGES[*]}"
    if (( DRY_RUN && (PENDING || !have_stow) )); then
        printf '   [dry-run] stow --restow --dir %s --target %s %s\n' "$REPO" "$HOME" "${STOW_PACKAGES[*]}"
        if (( have_stow )); then
            printf '   [dry-run] (link preview skipped: it needs the backups/folders above to exist first)\n'
        else
            printf '   [dry-run] (link preview skipped: stow is not installed yet)\n'
        fi
    elif (( DRY_RUN )); then
        stow --no --verbose --restow --dir "$REPO" --target "$HOME" "${STOW_PACKAGES[@]}" 2>&1 \
            | sed 's/^/   [dry-run] /' || true
    else
        stow --restow --dir "$REPO" --target "$HOME" "${STOW_PACKAGES[@]}"
        for pkg in "${STOW_PACKAGES[@]}"; do
            record link "$pkg"
        done
    fi
}

# ---------------------------------------------------------------------------
# Reload
# ---------------------------------------------------------------------------

reload_hyprland() {
    # Same script as the SUPER+SHIFT+R keybind; run from the repo so it works
    # even before bin/ is linked.
    local reload="$REPO/bin/.local/bin/hypr-reload"
    [[ -x "$reload" ]] || return 0
    log "Reloading configs:"
    "$reload" --quiet && log "All configs reloaded." \
        || warn "Reload reported errors (see above). Fix them, then run: hypr-reload"
}

(( DRY_RUN )) && log "Dry run: nothing will be changed."
choose_distro
install_packages
link_dotfiles
generate_theme
(( DRY_RUN )) || reload_hyprland
log "Done."
