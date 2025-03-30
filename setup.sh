#!/bin/bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

MYVIMRC=vimrc
VIMRC="$HOME/.vimrc"
BACKUP_DIR="$(dirname "$0")/backup"
NERDTREE_DIR="$HOME/.vim/pack/vendor/start/nerdtree"

COMMAND=$1
set -e

VALID_COMMANDS=("set" "restore")

init_submodules(){  
    git submodule update --init --recursive
}

setup(){
    mkdir -p "$BACKUP_DIR"  # Ensure backup directory exists

    if [ -f "$BACKUP_DIR/vimrc_old" ]; then
        echo "Backup already exists in $BACKUP_DIR!"
        read -r -p "Overwrite the existing backup? [y/n] " confirm
        if [[ ! $confirm =~ ^[yY]([eE][sS])?$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    if [ -f "$VIMRC" ]; then
        echo "Saving current vimrc to $BACKUP_DIR/vimrc_old."
        cp "$VIMRC" "$BACKUP_DIR/vimrc_old"
    else
        echo "No existing vimrc found. Creating a new one."
        touch "$BACKUP_DIR/no_vimrc"
    fi



    if [ ! -d "$HOME/.vim/pack/vendor/start" ]; then
        echo "Creating plugin directory."
        mkdir -p "$HOME/.vim/pack/vendor/start"
        init_submodules
        if [ -d nerdtree ]; then
            cp -r nerdtree "$NERDTREE_DIR"
        else
            echo "NERDTree not found! Skipping."
        fi
    elif [ ! -d "$NERDTREE_DIR" ]; then
        echo "Downloading and copying NERDTree to plugin directory."
        init_submodules
        if [ -d nerdtree ]; then
            cp -r nerdtree "$NERDTREE_DIR"
            touch "$BACKUP_DIR/nerdtree_installed"  # Mark that we installed it
        else
            echo "NERDTree directory missing!"
        fi
    else
        echo "NERDTree is already installed."
    fi

    cp "$MYVIMRC" "$HOME/.${MYVIMRC}"
}

restore(){
    if [ -f "$BACKUP_DIR/vimrc_old" ]; then
        echo "Restoring vimrc from backup."
        cp "$BACKUP_DIR/vimrc_old" "$VIMRC"
    else
        echo "No backup found! Cannot restore."
        exit 1
    fi

    if [ -f "$BACKUP_DIR/nerdtree_installed" ]; then
        echo "NERDTree was installed during setup. Removing it..."
        rm -rf "$NERDTREE_DIR"
        rm "$BACKUP_DIR/nerdtree_installed"
    fi
    if [ -f "$BACKUP_DIR/no_vimrc" ]; then
        echo ".vimrc was not here at the beginning. Removing it..."
        rm -rf "$VIMRC"
        rm "$BACKUP_DIR/no_vimrc"

    fi
}

print_help(){
    echo "Usage: $0 <command>"
    echo "Available commands:"
    echo "  set       - Set up the vim configuration and install NERDTree if needed"
    echo "  restore   - Restore the previous vim configuration and remove NERDTree if it was installed"
}

if [ "$COMMAND" = "set" ]; then
    setup
    echo "Done!"

elif [ "$COMMAND" = "restore" ]; then
    restore
    echo "Restored successfully."

else
    echo "Unknown or missing command: '$COMMAND'"
    print_help
    exit 1
fi
