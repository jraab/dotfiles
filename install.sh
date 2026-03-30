#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
BACKUP="$HOME/.dotfiles_old"

# Files to symlink: repo_path -> ~/.repo_path
files=(bashrc bash_profile gitconfig gitignore inputrc vimrc)

link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        local current
        current=$(readlink "$dst")
        if [[ "$current" == "$src" ]]; then
            echo "  ok: $dst (already linked)"
            return
        fi
        echo "  relink: $dst (was -> $current)"
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        echo "  backup: $dst -> $BACKUP/"
        mkdir -p "$BACKUP"
        mv "$dst" "$BACKUP/"
    fi
    ln -s "$src" "$dst"
    echo "  linked: $dst -> $src"
}

echo "Installing dotfiles from $DOTFILES"
echo

# Individual file symlinks
for f in "${files[@]}"; do
    link "$DOTFILES/$f" "$HOME/.$f"
done

# Directory symlink: ~/.config/bash -> ~/dotfiles/config/bash
mkdir -p "$HOME/.config"
link "$DOTFILES/config/bash" "$HOME/.config/bash"

echo
echo "Done. Backup of replaced files (if any) in $BACKUP"
