# yonko: minimal, adaptive zsh prompt.
#
#   ~ ❯                                   home / plain folders: one line
#   ~/Downloads ❯
#
#   yonko on ⎇ main ⇡1 !1 ?1              in a git repo: info line + input line
#   ❯
#
#   yonko on ⎇ main !1                    after a failed, slow command
#   ✗ 1 ❯                          took 12s
#
# Ink + one green accent, using only the terminal's 16 theme colors so it
# follows the kitty theme (light now, dark later):
#   bold ink = folder      green = branch, success arrow     faint = details
#   red = failed command / conflicts     yellow = rebase/merge in progress
#
# Git: ⇡ ahead  ⇣ behind  + staged  ! modified  ? untracked  = conflicts  ≡ stashes
# Shown only when relevant: virtualenv (via 󰌠 name), background jobs (✦1),
# user@host over SSH, root. Two git calls per prompt.

setopt prompt_subst
zmodload zsh/datetime 2>/dev/null   # $EPOCHREALTIME for command timing
autoload -Uz add-zsh-hook

VIRTUAL_ENV_DISABLE_PROMPT=1        # the prompt shows the venv itself

typeset -g _yonko_git="" _yonko_git_top="" _yonko_took="" _yonko_cmd_start=""
typeset -gi _yonko_first_prompt=1

# --- Git -----------------------------------------------------------------------

_yonko_git_info() {
    _yonko_git="" _yonko_git_top=""
    local -a paths
    paths=( ${(f)"$(command git rev-parse --git-dir --show-toplevel 2>/dev/null)"} )
    (( ${#paths} == 2 )) || return
    local gitdir=${paths[1]}
    _yonko_git_top=${paths[2]}

    local line branch="" oid="" ab
    local -i ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicts=0
    for line in ${(f)"$(command git status --porcelain=v2 --branch 2>/dev/null)"}; do
        case $line in
            "# branch.oid "*)  oid=${line#\# branch.oid } ;;
            "# branch.head "*) branch=${line#\# branch.head } ;;
            "# branch.ab "*)   ab=${line#\# branch.ab }
                               ahead=${${ab%% *}#+}; behind=${${ab##* }#-} ;;
            "1 "*|"2 "*)       [[ ${line[3]} != . ]] && (( staged++ ))
                               [[ ${line[4]} != . ]] && (( modified++ )) ;;
            "u "*)             (( conflicts++ )) ;;
            "? "*)             (( untracked++ )) ;;
        esac
    done

    # Detached HEAD: show the short commit instead of a branch name.
    [[ $branch == "(detached)" ]] && branch="@${oid[1,7]}"

    local -i stashes=0
    if [[ -f $gitdir/logs/refs/stash ]]; then
        local -a stash_lines=( ${(f)"$(<$gitdir/logs/refs/stash)"} )
        stashes=${#stash_lines}
    fi

    local op=""
    if   [[ -d $gitdir/rebase-merge || -d $gitdir/rebase-apply ]]; then op="rebasing"
    elif [[ -f $gitdir/MERGE_HEAD ]];       then op="merging"
    elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then op="cherry-picking"
    elif [[ -f $gitdir/REVERT_HEAD ]];      then op="reverting"
    elif [[ -f $gitdir/BISECT_LOG ]];       then op="bisecting"
    fi

    local s="%F{8}on%f %B%F{green}⎇ ${branch//\%/%%}%f%b"
    local meta=""
    (( ahead ))     && meta+=" ⇡${ahead}"
    (( behind ))    && meta+=" ⇣${behind}"
    (( staged ))    && meta+=" +${staged}"
    (( modified ))  && meta+=" !${modified}"
    (( untracked )) && meta+=" ?${untracked}"
    (( stashes ))   && meta+=" ≡${stashes}"
    [[ -n $meta ]]  && s+="%F{8}${meta}%f"
    (( conflicts )) && s+=" %F{red}=${conflicts}%f"
    [[ -n $op ]]    && s+=" %F{yellow}${op}%f"
    _yonko_git=$s
}

# --- Folder --------------------------------------------------------------------
# In a repo: bold repo name + the path inside it. Elsewhere: ~/... (last 3).

_yonko_folder() {
    if [[ -n $_yonko_git_top ]]; then
        local rel=${PWD#$_yonko_git_top}
        print -rn -- "%B${${_yonko_git_top:t}//\%/%%}%b${rel//\%/%%}"
    else
        print -rn -- "%B%(4~|…/%3~|%~)%b"
    fi
}

# --- Timing --------------------------------------------------------------------

_yonko_preexec() { _yonko_cmd_start=$EPOCHREALTIME }

_yonko_duration() {
    _yonko_took=""
    [[ -n $_yonko_cmd_start ]] || return
    local -F elapsed=$(( EPOCHREALTIME - _yonko_cmd_start ))
    _yonko_cmd_start=""
    (( elapsed < 2 )) && return
    local -i t=$elapsed
    if   (( t >= 3600 )); then _yonko_took="$(( t / 3600 ))h $(( t % 3600 / 60 ))m"
    elif (( t >= 60 ));   then _yonko_took="$(( t / 60 ))m $(( t % 60 ))s"
    else                       _yonko_took="${t}s"
    fi
}

# --- Assemble ------------------------------------------------------------------

_yonko_precmd() {
    _yonko_duration
    _yonko_git_info

    # Blank line between commands (not before the very first prompt).
    if (( _yonko_first_prompt )); then _yonko_first_prompt=0; else print; fi

    # Info: [root] [user@host] folder [on ⎇ branch ...] [via 󰌠 venv]
    local info=""
    info+="%(!.%B%F{red}root%f%b .)"
    [[ -n $SSH_CONNECTION ]] && info+="%F{8}%n@%m%f "
    info+="$(_yonko_folder)"
    [[ -n $_yonko_git ]] && info+=" ${_yonko_git}"
    if [[ -n $VIRTUAL_ENV ]]; then
        # ".venv" / "venv" say nothing: show the project folder instead.
        local venv=${VIRTUAL_ENV:t}
        [[ $venv == (.venv|venv|env|.env) ]] && venv=${VIRTUAL_ENV:h:t}
        info+=" %F{8}via 󰌠 ${venv//\%/%%}%f"
    fi

    # Input: [✦jobs] [✗ code] ❯   (arrow green on success, red on failure)
    local input="%(1j.%F{8}✦%j%f .)%(?..%F{red}✗ %?%f )%(?.%F{green}.%F{red})❯%f "

    # One line normally; two lines in a git repo, so branch info never crowds
    # what you type.
    if [[ -n $_yonko_git ]]; then
        PROMPT="${info}"$'\n'"${input}"
    else
        PROMPT="${info} ${input}"
    fi

    RPROMPT=""
    [[ -n $_yonko_took ]] && RPROMPT="%F{8}took ${_yonko_took}%f"
}

add-zsh-hook preexec _yonko_preexec
add-zsh-hook precmd  _yonko_precmd
