#!/bin/bash
set -e

# Basic helper functions for error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

MYVIMRC=vimrc
VIMRC="$HOME/.vimrc"
BASHRC="$HOME/.bashrc"
BACKUP_DIR="$(dirname "$0")/backup"
NERDTREE_DIR="$HOME/.vim/pack/vendor/start/nerdtree"
BASHMARKS_INSTALL_DIR="$HOME/.local/bin"

COMMAND=$1

# Ensure that BACKUP_DIR exists, or die if it cannot be created.
create_directory() {
    local dir="$1"
    if ! mkdir -p "$dir"; then
        die "Failed to create directory: $dir"
    fi
}

# Backup a file if it exists; otherwise, record that it was absent.
# Arguments:
#   $1: source file
#   $2: backup destination file (or a note file if absent)
backup_or_note() {
    local src="$1"
    local backup="$2"
    if [ -f "$src" ]; then
        echo "Backing up $src to $backup"
        cp "$src" "$backup" || die "Backup of $src to $backup failed"
    else
        echo "No $src found, noting..."
        # Touch a file so that we know the file did not exist originally.
        touch "$backup" || die "Cannot create note file $backup"
    fi
}

init_submodules() {
    try git submodule update --init --recursive
}

setup_bashmarks() {
    echo "Setting up bashmarks..."
    create_directory "$BASHMARKS_INSTALL_DIR"
    try cp bashmarks.sh "$BASHMARKS_INSTALL_DIR"

    # Backup .bashrc before modifying it if not already backed up.
    if ! grep -q "bashmarks.sh" "$BASHRC"; then
        backup_or_note "$BASHRC" "$BACKUP_DIR/bashrc_old"
        echo "source $BASHMARKS_INSTALL_DIR/bashmarks.sh" >> "$BASHRC"
    else
        echo "bashmarks already sourced in .bashrc"
    fi
}

setup_vim() {
    echo "Setting up Vim..."
    create_directory "$BACKUP_DIR"

    # Backup .vimrc or note that it was absent.
    backup_or_note "$VIMRC" "$BACKUP_DIR/vimrc_old"

    # Create plugin directory
    create_directory "$HOME/.vim/pack/vendor/start"

    init_submodules

    # Install NERDTree if available in the local 'nerdtree' directory.
    if [ -d nerdtree ]; then
        try cp -r nerdtree "$NERDTREE_DIR"
        touch "$BACKUP_DIR/nerdtree_installed"
    else
        echo "NERDTree not found, skipping its installation."
    fi

    # Copy our vimrc to $VIMRC
    try cp "$MYVIMRC" "$VIMRC"
}

setup() {
    setup_vim
    setup_bashmarks
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

    # Remove NERDTree if it was installed by setup.
    if [ -f "$BACKUP_DIR/nerdtree_installed" ]; then
        echo "Removing installed NERDTree..."
        rm -rf "$NERDTREE_DIR" || die "Failed to remove NERDTree"
        rm "$BACKUP_DIR/nerdtree_installed" || die "Failed to remove NERDTree marker"
    fi
}

print_help() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  setup      - Set up the Vim configuration and install NERDTree and bashmarks"
    echo "  restore  - Restore previous Vim and bash configuration"
}

case "$COMMAND" in
    setup)
        setup
        echo "Setup complete!"
        ;;
    restore)
        restore
        echo "Restored successfully!"
        ;;
    *)
        echo "Unknown or missing command: '$COMMAND'"
        print_help
        exit 1
        ;;
esac
