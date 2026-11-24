#!/usr/bin/env bash
# Undo ./install.sh: remove the symlinks, restore backed-up files, remove
# directories it created, and remove packages / the PPA it installed.
#
# Usage: ./uninstall.sh [--dry-run] [--keep-packages] [--yes]
#
#   --dry-run         Show what would happen, change nothing.
#   --keep-packages   Leave apt packages and the PPA installed.
#   --yes             Don't ask before removing packages.
#
# Only things recorded in ~/.local/state/hyprland-dotfiles/changes.log are
# undone, so packages you already had before install.sh are never removed.
# Only symlinks pointing into this repo are deleted.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-dotfiles"
STATE_LOG="$STATE_DIR/changes.log"

DRY_RUN=0
KEEP_PACKAGES=0
ASSUME_YES=0

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if (( DRY_RUN )); then
        printf '   [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
    case "$1" in
        --dry-run)       DRY_RUN=1 ;;
        --keep-packages) KEEP_PACKAGES=1 ;;
        --yes|-y)        ASSUME_YES=1 ;;
        -h|--help)       usage; exit 0 ;;
        *)               die "Unknown option: $1 (see --help)" ;;
    esac
    shift
done

(( EUID != 0 )) || die "Run as your normal user, not root. sudo is used where needed."

# Log lines of one type, newest first, as tab-separated fields.
entries() {
    [[ -f "$STATE_LOG" ]] || return 0
    tac "$STATE_LOG" | awk -F'\t' -v t="$1" '$1 == t'
}

# ---------------------------------------------------------------------------
# 1. Remove symlinks into this repo
# ---------------------------------------------------------------------------

# For each file a package provides, walk its target path from $HOME down and
# remove the first symlink that points into this repo. That handles both
# per-file links and folded directory links (e.g. ~/.config/hypr/modules).
declare -A UNLINKED=()

remove_links() {
    local pkg="$1" src rel cur part removed=0
    while IFS= read -r -d '' src; do
        rel="${src#"$REPO/$pkg/"}"
        cur="$HOME"
        IFS='/' read -r -a parts <<< "$rel"
        for part in "${parts[@]}"; do
            cur="$cur/$part"
            if [[ -L "$cur" ]]; then
                if [[ -n "${UNLINKED[$cur]:-}" ]]; then
                    removed=$((removed + 1))
                elif [[ "$(readlink -f "$cur")" == "$REPO/"* ]]; then
                    UNLINKED[$cur]=1
                    log "Unlinking ${cur/#$HOME/\~}"
                    run rm "$cur"
                    removed=$((removed + 1))
                fi
                break
            fi
            [[ -e "$cur" ]] || break
        done
    done < <(find "$REPO/$pkg" \( -type f -o -type l \) -print0)
    (( removed )) || log "Nothing linked for package: $pkg"
}

unlink_all() {
    local d
    for d in "$REPO"/*/; do
        remove_links "$(basename "$d")"
    done
}

# ---------------------------------------------------------------------------
# 2. Restore backups
# ---------------------------------------------------------------------------

# True if the path is (or sits under) a symlink into this repo, i.e. it is
# removed by step 1. Used so dry runs report what a real run would do.
is_repo_link() {
    [[ -L "$1" || -e "$1" ]] && [[ "$(readlink -f "$1")" == "$REPO/"* ]]
}

# True if something other than our own link occupies the path.
occupied() {
    [[ -e "$1" || -L "$1" ]] || return 1
    (( DRY_RUN )) && is_repo_link "$1" && return 1
    return 0
}

restore_backups() {
    local type target backup found=0
    while IFS=$'\t' read -r type target backup; do
        found=1
        if [[ ! -e "$backup" && ! -L "$backup" ]]; then
            warn "Backup missing, can't restore: $backup"
        elif occupied "$target"; then
            warn "Not restoring ${target/#$HOME/\~}: something is already there (backup kept at $backup)"
        else
            log "Restoring ${target/#$HOME/\~}"
            run mv "$backup" "$target"
        fi
    done < <(entries backup)
    (( found )) || log "No backed-up files to restore."
}

# Without a change log (e.g. linked by hand), fall back to the newest
# <file>.bak.* for any package file whose target is now empty.
restore_latest_backups() {
    local d src rel target latest
    for d in "$REPO"/*/; do
        while IFS= read -r -d '' src; do
            rel="${src#"$d"}"
            target="$HOME/$rel"
            occupied "$target" && continue
            latest="$(ls -1d "$target".bak.* 2>/dev/null | sort | tail -n1 || true)"
            [[ -n "$latest" ]] || continue
            log "Restoring ${target/#$HOME/\~} from $(basename "$latest")"
            run mv "$latest" "$target"
        done < <(find "$d" \( -type f -o -type l \) -print0)
    done
}

# ---------------------------------------------------------------------------
# 3. Remove directories install.sh created (only if empty)
# ---------------------------------------------------------------------------

remove_dirs() {
    local type dir
    while IFS=$'\t' read -r type dir; do
        [[ -d "$dir" ]] || continue
        if [[ -z "$(ls -A "$dir")" ]]; then
            log "Removing empty dir ${dir/#$HOME/\~}"
            run rmdir "$dir"
        elif (( DRY_RUN )); then
            printf '   [dry-run] rmdir %s (only if empty after the steps above)\n' "$dir"
        else
            warn "Keeping ${dir/#$HOME/\~}: not empty"
        fi
    done < <(entries mkdir)
}

# ---------------------------------------------------------------------------
# 4. Remove packages and PPA install.sh added
# ---------------------------------------------------------------------------

PACKAGES_REMOVED=1

remove_packages() {
    local type pkg pkgs=() ppas=()
    while IFS=$'\t' read -r type pkg; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" \
            && [[ ! " ${pkgs[*]} " == *" $pkg "* ]] && pkgs+=("$pkg")
    done < <(entries apt)
    while IFS=$'\t' read -r type pkg; do
        [[ ! " ${ppas[*]} " == *" $pkg "* ]] && ppas+=("$pkg")
    done < <(entries ppa)

    if (( ${#pkgs[@]} == 0 && ${#ppas[@]} == 0 )); then
        log "No packages or PPAs to remove."
        return
    fi

    if (( KEEP_PACKAGES )); then
        log "Keeping packages (--keep-packages): ${pkgs[*]:-none} ${ppas[*]:-}"
        PACKAGES_REMOVED=0
        return
    fi

    if (( ${#pkgs[@]} )); then
        log "Packages installed by install.sh: ${pkgs[*]}"
        if [[ " ${pkgs[*]} " == *" hyprland "* && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            warn "You are running Hyprland. It keeps running, but you won't be able to log back into it."
        fi
        if (( DRY_RUN )); then
            apt-get -s purge --auto-remove "${pkgs[@]}" 2>/dev/null \
                | awk '/^Purg/{print "   [dry-run] purge " $2}'
        else
            local yes=()
            (( ASSUME_YES )) && yes=(-y)
            # apt shows the full list and asks for confirmation (unless --yes).
            if ! sudo apt-get purge --auto-remove "${yes[@]}" "${pkgs[@]}"; then
                warn "Package removal cancelled or failed; keeping them recorded for next time."
                PACKAGES_REMOVED=0
                return
            fi
        fi
    fi

    for pkg in "${ppas[@]}"; do
        log "Removing $pkg"
        run sudo add-apt-repository --remove -y "$pkg"
    done
    (( ${#ppas[@]} )) && run sudo apt-get update
    return 0
}

# ---------------------------------------------------------------------------
# 5. Finish
# ---------------------------------------------------------------------------

finish_log() {
    (( DRY_RUN )) && return 0
    [[ -f "$STATE_LOG" ]] || return 0
    if (( PACKAGES_REMOVED )); then
        # Fully reverted: nothing left to track.
        rm "$STATE_LOG"
        rmdir "$STATE_DIR" 2>/dev/null || true
    else
        # Keep only the package lines so a later run can still remove them.
        local tmp="$STATE_LOG.tmp"
        awk -F'\t' '$1 == "apt" || $1 == "ppa"' "$STATE_LOG" > "$tmp"
        mv "$tmp" "$STATE_LOG"
    fi
}

reload_hyprland() {
    (( DRY_RUN )) && return 0
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -f "$HOME/.config/hypr/hyprland.lua" ]] || return 0
    command -v hyprctl >/dev/null || return 0
    hyprctl reload >/dev/null && log "Reloaded running Hyprland."
}

# Generated theme files (kitty/Waybar/rofi/hyprlock/mako/GTK colors) live in
# the apps' config folders, outside the repo: remove them first.
clean_theme() {
    local theme="$REPO/bin/.local/bin/hypr-theme"
    [[ -x "$theme" ]] || return 0
    if (( DRY_RUN )); then
        printf '   [dry-run] hypr-theme clean (remove generated theme files)\n'
    else
        "$theme" clean | sed 's/^/:: /'
    fi
}

(( DRY_RUN )) && log "Dry run: nothing will be changed."
if [[ ! -f "$STATE_LOG" ]]; then
    warn "No change log at $STATE_LOG."
    warn "Removing repo symlinks and restoring the newest .bak files only; packages are left alone."
    clean_theme
    unlink_all
    restore_latest_backups
    reload_hyprland
    log "Done."
    exit 0
fi

clean_theme
unlink_all
restore_backups
remove_dirs
command -v apt-get >/dev/null && remove_packages
finish_log
reload_hyprland
log "Done."
