# Chezmoi to Symlink Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace chezmoi with a symlink-based dotfile manager using `~/dotfiles/` as the canonical source, eliminating one-way overwrite issues.

**Architecture:** Plain files in `~/dotfiles/` are symlinked into `$HOME` by a one-time `install.sh` script. Chezmoi templates are converted to runtime OS detection. Git operations happen directly on the repo.

**Tech Stack:** Bash, Git, symlinks

---

### Task 1: Clean the repo and set up directory structure

The existing `~/dotfiles/` repo has stale files from an old symlink approach (on `master`) and the chezmoi version lives on `main` at the same remote. We need a clean starting point.

**Files:**
- Remove: `~/dotfiles/.bashrc` (old duplicate)
- Remove: `~/dotfiles/bashrc` (old version)
- Remove: `~/dotfiles/bash/` (old directory)
- Remove: `~/dotfiles/vimrc` (old version)
- Remove: `~/dotfiles/makesymlinks.sh` (replaced by install.sh)
- Remove: `~/dotfiles/install.sh` (old version, will be rewritten)
- Create: `~/dotfiles/config/bash/` (directory)

- [ ] **Step 1: Reset repo to main branch content**

The `~/dotfiles/` repo is on `master` (old). The chezmoi repo at `~/.local/share/chezmoi/` has the current content on `main` at the same remote. We need to point `~/dotfiles/` at `main`.

```bash
cd ~/dotfiles
git fetch origin
git checkout main
```

If this fails because of local changes on master:

```bash
git stash
git checkout main
```

- [ ] **Step 2: Remove old files that won't be needed**

```bash
cd ~/dotfiles
rm -f .bashrc makesymlinks.sh install.sh
rm -rf bash/
```

- [ ] **Step 3: Create the config directory structure**

```bash
mkdir -p ~/dotfiles/config/bash
```

- [ ] **Step 4: Commit the cleanup**

```bash
cd ~/dotfiles
git add -A
git commit -m "clean up old files, prepare for symlink migration"
```

---

### Task 2: Convert bashrc template to plain file

**Files:**
- Create: `~/dotfiles/bashrc`
- Reference: `~/.local/share/chezmoi/dot_bashrc.tmpl` (source of truth for current content)

- [ ] **Step 1: Write the converted bashrc**

Create `~/dotfiles/bashrc` with this content (template directives replaced with runtime detection):

```bash
# ~/.bashrc - Interactive shell configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source shared config
[[ -f ~/.config/bash/core ]] && source ~/.config/bash/core
[[ -f ~/.config/bash/aliases ]] && source ~/.config/bash/aliases

# Source OS-specific config
if [[ "$(uname)" == "Darwin" ]]; then
    [[ -f ~/.config/bash/macos ]] && source ~/.config/bash/macos
else
    [[ -f ~/.config/bash/linux ]] && source ~/.config/bash/linux
fi

# Source sync functions (rsync project tooling)
[[ -f ~/.config/bash/sync-functions ]] && source ~/.config/bash/sync-functions
```

- [ ] **Step 2: Verify the file looks correct**

```bash
cat ~/dotfiles/bashrc
```

Expected: The content above, no chezmoi template directives (`{{ }}`), no "Managed by chezmoi" comment.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add bashrc
git commit -m "add bashrc with runtime OS detection"
```

---

### Task 3: Convert bash_profile template to plain file

**Files:**
- Create: `~/dotfiles/bash_profile`
- Reference: `~/.local/share/chezmoi/dot_bash_profile.tmpl`

- [ ] **Step 1: Write the converted bash_profile**

Create `~/dotfiles/bash_profile`:

```bash
# ~/.bash_profile - Login shell configuration

# Disable bell
bind 'set bell-style none' 2>/dev/null

# Source .bashrc for interactive settings
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

# Conda - check common install locations
for conda_sh in \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/anaconda3/etc/profile.d/conda.sh"; do
    if [[ -f "$conda_sh" ]]; then
        source "$conda_sh"
        break
    fi
done
```

- [ ] **Step 2: Commit**

```bash
cd ~/dotfiles
git add bash_profile
git commit -m "add bash_profile with unified conda detection"
```

---

### Task 4: Convert gitconfig template to plain file

**Files:**
- Create: `~/dotfiles/gitconfig`
- Reference: `~/.local/share/chezmoi/dot_gitconfig.tmpl`

- [ ] **Step 1: Write the converted gitconfig**

Create `~/dotfiles/gitconfig`:

```
# ~/.gitconfig - Git configuration

[user]
    name = Jesse Raab
    email = jesse.r.raab@gmail.com

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    ca = commit --amend
    d = diff
    ds = diff --staged
    lg = log --oneline --graph --decorate -20
    lga = log --oneline --graph --decorate --all
    last = log -1 HEAD --stat
    unstage = reset HEAD --

[core]
    excludesfile = ~/.gitignore

[filter "lfs"]
    process = git-lfs filter-process
    required = true
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
```

- [ ] **Step 2: Commit**

```bash
cd ~/dotfiles
git add gitconfig
git commit -m "add gitconfig with hardcoded user info"
```

---

### Task 5: Copy remaining dotfiles (no conversion needed)

**Files:**
- Create: `~/dotfiles/gitignore`
- Create: `~/dotfiles/inputrc`
- Create: `~/dotfiles/vimrc`
- Source: `~/.local/share/chezmoi/dot_gitignore`, `dot_inputrc`, `dot_vimrc`

- [ ] **Step 1: Copy the files, removing chezmoi comments**

```bash
cd ~/dotfiles
# These files have no template directives, just copy and clean up comments
sed 's/# Managed by chezmoi//' ~/.local/share/chezmoi/dot_gitignore > gitignore
sed 's/# Managed by chezmoi//' ~/.local/share/chezmoi/dot_inputrc > inputrc
cp ~/.local/share/chezmoi/dot_vimrc vimrc
```

- [ ] **Step 2: Verify no chezmoi references remain**

```bash
grep -r "chezmoi" ~/dotfiles/gitignore ~/dotfiles/inputrc ~/dotfiles/vimrc
```

Expected: No output (no matches).

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add gitignore inputrc vimrc
git commit -m "add gitignore, inputrc, vimrc"
```

---

### Task 6: Copy bash config modules

**Files:**
- Create: `~/dotfiles/config/bash/core`
- Create: `~/dotfiles/config/bash/macos`
- Create: `~/dotfiles/config/bash/linux`
- Create: `~/dotfiles/config/bash/sync-functions`
- Create: `~/dotfiles/config/bash/aliases` (with updated dotpush/dotpull/dotcd)
- Source: `~/.config/bash/*` (live files) and `~/.local/share/chezmoi/private_dot_config/bash/*`

- [ ] **Step 1: Copy core, macos, linux, sync-functions from live system**

We copy from the live `~/.config/bash/` since those are the current files. Remove "Managed by chezmoi" comments.

```bash
cd ~/dotfiles/config/bash
for f in core macos linux sync-functions; do
    sed 's/# Managed by chezmoi.*$//' ~/.config/bash/$f > "$f"
done
```

- [ ] **Step 2: Update sync-functions to remove chezmoi dependency**

In `~/dotfiles/config/bash/sync-functions`, update the `claude-sync` function. Replace the pull action's `chezmoi update` with `dotpull`:

Find this block in the `claude-sync` function:

```bash
        echo "==> Updating chezmoi..."
        chezmoi update
```

Replace with:

```bash
        echo "==> Pulling dotfiles..."
        git -C ~/dotfiles pull
```

- [ ] **Step 3: Write the updated aliases file**

Create `~/dotfiles/config/bash/aliases`:

```bash
# ~/.config/bash/aliases - Shared aliases for all platforms

# ls family - OS-specific file defines base ls (color, dirs-first, long format)
alias ll='ls -lh'
alias la='ls -alH'
alias cc='claude code'

alias longleaf='ssh -X jraab@longleaf.its.unc.edu'

# Dotfile shortcuts
alias dotcd='cd ~/dotfiles'

dotpush() {
    local msg="${1:-update dotfiles}"
    git -C ~/dotfiles add -A && \
    git -C ~/dotfiles commit -m "$msg" && \
    git -C ~/dotfiles push
}

dotpull() {
    git -C ~/dotfiles pull
}
```

- [ ] **Step 4: Verify no chezmoi references in bash config files**

```bash
grep -r "chezmoi" ~/dotfiles/config/bash/
```

Expected: No output.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add config/
git commit -m "add bash config modules, update dotpush/dotpull, remove chezmoi from claude-sync"
```

---

### Task 7: Write install.sh

**Files:**
- Create: `~/dotfiles/install.sh`

- [ ] **Step 1: Write the install script**

Create `~/dotfiles/install.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x ~/dotfiles/install.sh
```

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add install.sh
git commit -m "add install.sh symlink manager"
```

---

### Task 8: Remove chezmoi-specific files from repo

**Files:**
- Remove: `~/dotfiles/dot_*` (chezmoi-prefixed files, if any remain after Task 1)
- Remove: `~/dotfiles/.chezmoi*` (chezmoi config files)
- Remove: `~/dotfiles/private_dot_*` (chezmoi private files)
- Modify: `~/dotfiles/README.md`

- [ ] **Step 1: Remove chezmoi files**

```bash
cd ~/dotfiles
rm -f .chezmoi.toml.tmpl .chezmoiexternal.toml .chezmoiignore
rm -rf private_dot_claude private_dot_config
rm -f dot_bash_profile.tmpl dot_bashrc.tmpl dot_gitconfig.tmpl dot_gitignore dot_inputrc dot_vimrc
```

- [ ] **Step 2: Update README.md**

Create `~/dotfiles/README.md`:

```markdown
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
```

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add -A
git commit -m "remove chezmoi files, update README"
```

---

### Task 9: Run install.sh and verify

**Files:**
- No new files — this is the verification step

- [ ] **Step 1: Run the install script**

```bash
cd ~/dotfiles
./install.sh
```

Expected output: Each file shows either "linked" (new symlink created) or "backup" (existing file moved to `~/.dotfiles_old/`). The `~/.config/bash` directory should be backed up and replaced with a symlink.

- [ ] **Step 2: Verify symlinks are correct**

```bash
ls -la ~/.bashrc ~/.bash_profile ~/.gitconfig ~/.gitignore ~/.inputrc ~/.vimrc ~/.config/bash
```

Expected: Each shows `->` pointing into `~/dotfiles/`.

- [ ] **Step 3: Source bashrc and verify shell works**

```bash
source ~/.bashrc
```

Expected: No errors. Prompt should still show git branch, aliases should work (`ll`, `longleaf`, `dotcd`).

- [ ] **Step 4: Verify dotpush and dotpull are available**

```bash
type dotpush
type dotpull
```

Expected: Both show as functions.

- [ ] **Step 5: Verify claude-sync no longer references chezmoi**

```bash
type claude-sync
```

Expected: Function body shows `git -C ~/dotfiles pull` instead of `chezmoi update`.

- [ ] **Step 6: Verify git operations work**

```bash
dotcd
git status
git log --oneline -5
```

Expected: Clean status, recent commits visible.

---

### Task 10: Clean up chezmoi

**Files:**
- Remove: `~/.local/share/chezmoi/`
- Remove: `~/.config/chezmoi/`
- Remove: `~/.dotfiles_old/` (optional, after verifying backup contents)

- [ ] **Step 1: Verify everything works before removing chezmoi**

Run a quick sanity check — open a new terminal tab/window and confirm your prompt, aliases, and git all work.

- [ ] **Step 2: Remove chezmoi data and config**

```bash
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
```

- [ ] **Step 3: Uninstall chezmoi**

```bash
brew uninstall chezmoi
```

- [ ] **Step 4: Push to GitHub**

```bash
cd ~/dotfiles
git push origin main
```

- [ ] **Step 5: Verify the old master branch can be cleaned up**

The `master` branch on the remote is the old symlink version. It's fully superseded.

```bash
git push origin --delete master
```

---

### Task 11: Document migration for other machines

No files to create — this is a reference for what to do on the other 2 macOS machines and the Linux server.

- [ ] **Step 1: On each other machine, run these commands:**

```bash
# Back up existing chezmoi-managed files (just in case)
mkdir -p ~/.dotfiles_old
cp ~/.bashrc ~/.bash_profile ~/.gitconfig ~/.gitignore ~/.inputrc ~/.vimrc ~/.dotfiles_old/ 2>/dev/null

# Remove old dotfiles repo if it exists
rm -rf ~/dotfiles

# Clone fresh
git clone https://github.com/jraab/dotfiles.git ~/dotfiles

# Install symlinks
cd ~/dotfiles
./install.sh

# Remove chezmoi
rm -rf ~/.local/share/chezmoi ~/.config/chezmoi
brew uninstall chezmoi 2>/dev/null  # or: sudo apt remove chezmoi on Linux

# Open a new terminal and verify
source ~/.bashrc
```
