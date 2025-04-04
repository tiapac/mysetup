#!/bin/bash

# File to store bookmarks
SDIRS="${SDIRS:-$HOME/.sdirs}"
touch "$SDIRS"
chmod 600 "$SDIRS"

RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No color


# Print help
check_help() {
    if [[ "$1" =~ ^(-h|--help|-help)$ ]]; then
        echo ""
        echo "s <bookmark_name> - Saves the current directory as <bookmark_name>"
        echo "g <bookmark_name> - Goes to the directory associated with <bookmark_name>"
        echo "p <bookmark_name> - Prints the directory associated with <bookmark_name>"
        echo "d <bookmark_name> - Deletes the bookmark"
        echo "l                 - Lists all bookmarks"
        kill -SIGINT $$
    fi
}
# Helper: validate bookmark name
_bookmark_name_valid() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "ERROR: Bookmark name required"
        return 1
    elif [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "ERROR: Invalid bookmark name. Use only letters, numbers, and underscores."
        return 1
    fi
    return 0
}

# List raw bookmark names
_l() {
    source "$SDIRS"
    env | grep "^DIR_" | cut -c5- | sort | cut -f1 -d "="
}

# Helper: remove matching line from file
_purge_line() {
    local file="$1"
    local pattern="$2"
    if [[ -s "$file" ]]; then
        local tmp
        tmp="$(mktemp -t bashmarks.XXXXXX)" || exit 1
        trap "command rm -f -- '$tmp'" EXIT

        grep -v "$pattern" "$file" > "$tmp"
        command mv "$tmp" "$file"
        trap - EXIT
    fi
}


# Save current directory to a bookmark
s() {
    check_help "$1"
    _bookmark_name_valid "$1" || return

    _purge_line "$SDIRS" "export DIR_$1="
    CURDIR="${PWD/#$HOME/\$HOME}"  # replace $HOME with literal
    echo "export DIR_$1=\"$CURDIR\"" >> "$SDIRS"
}

# Jump to a bookmark
g() {
    check_help "$1"
    source "$SDIRS"

    local varname="DIR_$1"
    local target="${!varname}"

    if [[ -d "$target" ]]; then
        cd "$target"
    elif [[ -z "$target" ]]; then
        echo -e "${RED}WARNING: Bookmark '$1' not found${NC}"
    else
        echo -e "${RED}WARNING: Target directory '$target' does not exist${NC}"
    fi
}

# Print a bookmark
p() {
    check_help "$1"
    source "$SDIRS"
    local varname="DIR_$1"
    echo "${!varname}"
}

# Delete a bookmark
d() {
    check_help "$1"
    _bookmark_name_valid "$1" || return

    _purge_line "$SDIRS" "export DIR_$1="
    unset "DIR_$1"
}

# List bookmarks
l() {
    check_help "$1"
    source "$SDIRS"
    env | sort | awk -v yellow="$YELLOW" -v nc="$NC" '/^DIR_.+/ {
        split(substr($0,5), parts, "=");
        printf "%s%-20s%s %s\n", yellow, parts[1], nc, parts[2]
    }'
}

# Bash tab-completion
_comp() {
    local curw
    COMPREPLY=()
    curw="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "$(_l)" -- "$curw") )
}

complete -F _comp g
complete -F _comp p
complete -F _comp d
