#!/bin/bash
set -e

# Basic helper functions for error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

MYVIMRC=vimrc
VIMRC="$HOME/.vimrc"
BASHRC="$HOME/.bashrc"
BACKUP_DIR="$(dirname "$0")/setup_backup"
NERDTREE_DIR="$HOME/.vim/pack/vendor/start/nerdtree"
BASHMARKS_INSTALL_DIR="$HOME/.local/bin"

MYSHELL='"[\t - \$(date +%d.%m.%Y)]\[$(tput setaf 7)\][\#] \[$(tput bold)\]\[$(tput setaf 4)\]\[$(tput setaf 5)\]\u\[$(tput setaf 4)\]@\[$(tput setaf 5)\]\h:\[$(tput setaf 3)\]\w\[$(tput setaf 4)\]\[$(tput setaf 2)\]\\$\[$(tput sgr0)\]"'



COMMAND=$1

# Ensure that BACKUP_DIR exists or exit if it cannot be created.
create_directory() {
    local dir="$1"
    if ! mkdir -p "$dir"; then
        die "Failed to create directory: $dir"
    fi
}

# Backup a file if it exists; otherwise, create a note file.
# If a backup already exists, prompt before overwriting.
backup_or_note() {
    local src="$1"
    local backup="$2"
    if [ -f "$src" ]; then
        if [ -f "$backup" ]; then
            echo 
            die "Backup file '$backup' already exists. Clean up first."
            #read -r -p "Overwrite the existing backup? [y/n] " confirm
            #if [[ ! "$confirm" =~ ^[yY] ]]; then
            #    die "User declined to overwrite backup $backup."
            #fi
        fi
        echo "Backing up $src to $backup."
        cp "$src" "$backup" || die "Backup of $src to $backup failed."
    else
        echo "No $src found; creating a note file at $backup."
        touch "$backup" || die "Cannot create note file $backup."
    fi
}

init_submodules() {
    try git submodule update --init --recursive
}

setup_bashmarks() {
    echo "Setting up bashmarks..."
    create_directory "$BASHMARKS_INSTALL_DIR"
    try cp bashmarks.sh "$BASHMARKS_INSTALL_DIR"
    try source $BASHRC
    # Backup .bashrc before modifying it if not already backed up.
    if ! grep -q "bashmarks.sh" "$BASHRC"; then
        #backup_or_note "$BASHRC" "$BACKUP_DIR/bashrc_old"
        echo "source $BASHMARKS_INSTALL_DIR/bashmarks.sh" >> "$BASHRC"
    else
        echo "bashmarks already sourced in .bashrc."
    fi
}

setup_shell(){
    echo "Setting up a nice shell..."
    if ! grep -q "export PS1" "$BASHRC"; then
        #backup_or_note "$BASHRC" "$BACKUP_DIR/bashrc_old"
        echo "export PS1=$MYSHELL" >> "$BASHRC"
    else
        echo "Shell is already set in  .bashrc."
    fi

}



setup_vim() {
    echo "Setting up Vim..."
    

    # Backup .vimrc or note that it was absent.
    backup_or_note "$VIMRC" "$BACKUP_DIR/vimrc_old"

    # Create plugin directory.
    create_directory "$HOME/.vim/pack/vendor/start"

    init_submodules

    # Install NERDTree if available in the local 'nerdtree' directory.
    if [ -d nerdtree ]; then
        try cp -r nerdtree "$NERDTREE_DIR"
        touch "$BACKUP_DIR/nerdtree_installed"
    else
        echo "NERDTree not found; skipping its installation."
    fi

    # Copy our vimrc to $VIMRC.
    try cp "$MYVIMRC" "$VIMRC"
}

backup_bashrc(){
    create_directory "$BACKUP_DIR"
    backup_or_note "$BASHRC" "$BACKUP_DIR/bashrc_old"
}
setup() {
    backup_bashrc
    setup_shell
    setup_vim
    setup_bashmarks
    source $HOME/.bashrc
}

restore() {
    echo "Restoring backups..."

    # Restore vimrc from backup if it exists.
    if [ -f "$BACKUP_DIR/vimrc_old" ]; then
        try cp "$BACKUP_DIR/vimrc_old" "$VIMRC"
    else
        echo "No vimrc backup found; nothing to restore for .vimrc."
    fi

    # Restore bashrc from backup if it exists.
    if [ -f "$BACKUP_DIR/bashrc_old" ]; then
        try cp "$BACKUP_DIR/bashrc_old" "$BASHRC"
    else
        echo "No bashrc backup found; nothing to restore for .bashrc."
    fi

    # Remove NERDTree if it was installed during setup.
    if [ -f "$BACKUP_DIR/nerdtree_installed" ]; then
        echo "Removing installed NERDTree..."
        rm -rf "$NERDTREE_DIR" || die "Failed to remove NERDTree"
        rm "$BACKUP_DIR/nerdtree_installed" || die "Failed to remove NERDTree marker"
    fi
    
}

print_help() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  set      - Set up the Vim configuration and install NERDTree and bashmarks"
    echo "  restore  - Restore previous Vim and bash configuration"
}

case "$COMMAND" in
    setup)
        setup
        source $BASHRC
        echo "Setup complete!" 
        ;;
        
    restore)
        restore
        source $BASHRC
        echo "Restored successfully!"
        ;;
    *)
        echo "Unknown or missing command: '$COMMAND'"
        print_help
        exit 1
        ;;
esac
