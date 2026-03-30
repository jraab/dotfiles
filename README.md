# Dotfiles

Shell configuration for macOS and Linux (UNC Longleaf).

## Setup

```bash
git clone https://github.com/jraab/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Usage

Edit files anywhere — symlinks mean `~/.bashrc` and `~/dotfiles/bashrc` are the same file.

```bash
dotpush "message"   # commit and push changes
dotpull             # pull changes on another machine
dotcd               # cd into ~/dotfiles
```

## Structure

| Repo file | Symlinked to |
|-----------|-------------|
| `bashrc` | `~/.bashrc` |
| `bash_profile` | `~/.bash_profile` |
| `config/bash/` | `~/.config/bash/` |
| `gitconfig` | `~/.gitconfig` |
| `gitignore` | `~/.gitignore` |
| `inputrc` | `~/.inputrc` |
| `vimrc` | `~/.vimrc` |
