#!/bin/bash
# install.sh

DOTFILES_DIR="$HOME/dotfiles"

# Create symlinks
ln -sf "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/bash/functions/sync-functions" "$HOME/.config/bash/sync-functions"
ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
