# Chezmoi Dotfiles Migration - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate dotfiles to chezmoi with modular bash config and OS-aware templating across 4 machines (3 macOS, 1 Linux).

**Architecture:** Chezmoi source directory at `~/.local/share/chezmoi/` backed by `github.com/jraab/dotfiles`. Bash config split into modular files under `~/.config/bash/`. Go templates used only where OS differences exist.

**Tech Stack:** chezmoi v2.69+, bash, Go text/template

**Reference:** See `docs/plans/2026-02-12-chezmoi-migration-design.md` for design rationale.

---

### Task 1: Reset chezmoi source directory

The existing chezmoi source has a stale `symlink_dot_bashrc` from a previous attempt. We need a clean start connected to the GitHub repo.

**Files:**
- Modify: `~/.local/share/chezmoi/` (wipe and reinit)

**Step 1: Remove stale chezmoi source content (keep .git)**

```bash
cd ~/.local/share/chezmoi
# Remove stale managed file, keep .git
rm -f symlink_dot_bashrc
```

**Step 2: Connect chezmoi repo to GitHub remote**

```bash
cd ~/.local/share/chezmoi
git remote add origin https://github.com/jraab/dotfiles.git 2>/dev/null || git remote set-url origin https://github.com/jraab/dotfiles.git
```

Note: The chezmoi source repo will become the **new** dotfiles repo. The old `~/dotfiles` repo content will be retired after migration. The GitHub remote will be force-pushed with the new chezmoi structure in Task 9.

**Step 3: Verify**

```bash
chezmoi source-path
# Expected: /Users/jraab/.local/share/chezmoi

ls -la ~/.local/share/chezmoi/
# Expected: only .git directory, no other files
```

**Step 4: Commit**

No commit yet - empty directory.

---

### Task 2: Create modular bash config files

Split the current monolithic `.bashrc` into focused modules under `~/.config/bash/`.

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/bash/core`
- Create: `~/.local/share/chezmoi/private_dot_config/bash/aliases`
- Create: `~/.local/share/chezmoi/private_dot_config/bash/macos`
- Create: `~/.local/share/chezmoi/private_dot_config/bash/linux`
- Create: `~/.local/share/chezmoi/private_dot_config/bash/sync-functions`

**Step 1: Create directory structure**

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_config/bash
```

**Step 2: Create `core` (shared PATH, exports, prompt settings)**

Write to `~/.local/share/chezmoi/private_dot_config/bash/core`:

```bash
# ~/.config/bash/core - Shared shell settings for all platforms
# Managed by chezmoi - edit source at ~/.local/share/chezmoi/

# PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Terminal
export TERM=xterm-color

# Editor
export EDITOR=vim

# History
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Shell options
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
```

**Step 3: Create `aliases` (shared across all machines)**

Write to `~/.local/share/chezmoi/private_dot_config/bash/aliases`:

```bash
# ~/.config/bash/aliases - Shared aliases for all platforms
# Managed by chezmoi

alias ll='ls -alh'
alias longleaf='ssh -X jraab@longleaf.its.unc.edu'
```

**Step 4: Create `macos` (macOS-specific settings)**

Write to `~/.local/share/chezmoi/private_dot_config/bash/macos`:

```bash
# ~/.config/bash/macos - macOS-specific shell settings
# Managed by chezmoi

# Colors
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export LS_OPTS='--color=auto'

# Homebrew (Apple Silicon vs Intel)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Silence zsh default shell warning on macOS
export BASH_SILENCE_DEPRECATION_WARNING=1
```

**Step 5: Create `linux` (Linux-specific settings)**

Write to `~/.local/share/chezmoi/private_dot_config/bash/linux`:

```bash
# ~/.config/bash/linux - Linux-specific shell settings
# Managed by chezmoi

# Colors
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export LS_COLORS='di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
alias ls='ls --color=auto'
```

**Step 6: Copy sync-functions (exact copy from current repo)**

```bash
cp ~/dotfiles/bash/sync-functions ~/.local/share/chezmoi/private_dot_config/bash/sync-functions
```

**Step 7: Verify bash syntax on all files**

```bash
for f in ~/.local/share/chezmoi/private_dot_config/bash/*; do
    echo "Checking $f..."
    bash -n "$f"
done
# Expected: no errors
```

**Step 8: Commit**

```bash
cd ~/.local/share/chezmoi
git add private_dot_config/
git commit -m "feat: add modular bash config (core, aliases, macos, linux, sync-functions)"
```

---

### Task 3: Create templated .bashrc

The `.bashrc` uses chezmoi Go templates to source the correct OS-specific module.

**Files:**
- Create: `~/.local/share/chezmoi/dot_bashrc.tmpl`

**Step 1: Write the templated .bashrc**

Write to `~/.local/share/chezmoi/dot_bashrc.tmpl`:

```
# ~/.bashrc - Interactive shell configuration
# Managed by chezmoi ({{ .chezmoi.os }}/{{ .chezmoi.arch }})
# Do not edit directly - run: chezmoi edit ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source shared config
[[ -f ~/.config/bash/core ]] && source ~/.config/bash/core
[[ -f ~/.config/bash/aliases ]] && source ~/.config/bash/aliases

# Source OS-specific config
{{ if eq .chezmoi.os "darwin" -}}
[[ -f ~/.config/bash/macos ]] && source ~/.config/bash/macos
{{ else -}}
[[ -f ~/.config/bash/linux ]] && source ~/.config/bash/linux
{{ end -}}

# Source sync functions (rsync project tooling)
[[ -f ~/.config/bash/sync-functions ]] && source ~/.config/bash/sync-functions
```

**Step 2: Verify template renders correctly**

```bash
chezmoi execute-template < ~/.local/share/chezmoi/dot_bashrc.tmpl
# Expected: renders with "darwin" and macos source line (no linux line)
```

**Step 3: Preview what chezmoi would write**

```bash
chezmoi diff
# Expected: shows .bashrc diff (old symlink target vs new content)
```

**Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_bashrc.tmpl
git commit -m "feat: add templated .bashrc with OS-specific module sourcing"
```

---

### Task 4: Create templated .bash_profile

Login shell setup: sources `.bashrc`, sets up conda with OS-aware paths.

**Files:**
- Create: `~/.local/share/chezmoi/dot_bash_profile.tmpl`

**Step 1: Write the templated .bash_profile**

Write to `~/.local/share/chezmoi/dot_bash_profile.tmpl`:

```
# ~/.bash_profile - Login shell configuration
# Managed by chezmoi ({{ .chezmoi.os }}/{{ .chezmoi.arch }})
# Do not edit directly - run: chezmoi edit ~/.bash_profile

# Disable bell
bind 'set bell-style none' 2>/dev/null

# Source .bashrc for interactive settings
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

{{ if eq .chezmoi.os "darwin" -}}
# Conda (macOS - miniconda3)
if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [[ -d "$HOME/miniconda3" ]]; then
    export PATH="$HOME/miniconda3/bin:$PATH"
fi
{{ else -}}
# Conda (Linux)
if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
fi
{{ end -}}
```

**Step 2: Verify template renders**

```bash
chezmoi execute-template < ~/.local/share/chezmoi/dot_bash_profile.tmpl
# Expected: renders with darwin/miniconda3 block
```

**Step 3: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_bash_profile.tmpl
git commit -m "feat: add templated .bash_profile with OS-aware conda setup"
```

---

### Task 5: Add .vimrc and .gitconfig

Non-templated vimrc, templated gitconfig for name/email.

**Files:**
- Create: `~/.local/share/chezmoi/dot_vimrc`
- Create: `~/.local/share/chezmoi/dot_gitconfig.tmpl`

**Step 1: Copy vimrc (exact, no templates)**

```bash
cp ~/dotfiles/vimrc ~/.local/share/chezmoi/dot_vimrc
```

**Step 2: Write templated .gitconfig**

Write to `~/.local/share/chezmoi/dot_gitconfig.tmpl`:

```
# ~/.gitconfig - Git configuration
# Managed by chezmoi

[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
    excludesfile = ~/.gitignore

[filter "lfs"]
    process = git-lfs filter-process
    required = true
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
```

**Step 3: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_vimrc dot_gitconfig.tmpl
git commit -m "feat: add vimrc and templated gitconfig"
```

---

### Task 6: Add Claude Code settings

Sync the portable Claude Code configuration.

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_claude/settings.json`

**Step 1: Create directory and copy settings**

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_claude
cp ~/.claude/settings.json ~/.local/share/chezmoi/private_dot_claude/settings.json
```

Note: We do NOT sync `installed_plugins.json` because it contains machine-specific absolute paths (cache directories). The `settings.json` contains `enabledPlugins` which is enough - Claude Code auto-installs plugins listed there on first run.

**Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add private_dot_claude/
git commit -m "feat: add Claude Code settings"
```

---

### Task 7: Set up chezmoi config (.chezmoi.toml.tmpl and .chezmoiignore)

Configure per-machine data prompts and OS-conditional file ignoring.

**Files:**
- Create: `~/.local/share/chezmoi/.chezmoi.toml.tmpl`
- Create: `~/.local/share/chezmoi/.chezmoiignore`

**Step 1: Write .chezmoi.toml.tmpl**

This prompts for name/email on `chezmoi init` if not already set, and stores per-machine config.

Write to `~/.local/share/chezmoi/.chezmoi.toml.tmpl`:

```
{{- $email := promptStringOnce . "email" "Git email address" -}}
{{- $name := promptStringOnce . "name" "Full name" -}}

[data]
    email = {{ $email | quote }}
    name = {{ $name | quote }}
```

**Step 2: Write .chezmoiignore**

Write to `~/.local/share/chezmoi/.chezmoiignore`:

```
# README is for humans reading the repo, not a managed dotfile
README.md
docs/

# Skip Claude Code config on Linux (not installed there)
{{ if ne .chezmoi.os "darwin" }}
.claude/**
{{ end }}
```

**Step 3: Verify ignore works**

```bash
chezmoi managed
# Expected: lists .bashrc, .bash_profile, .vimrc, .gitconfig,
#           .config/bash/*, .claude/settings.json
# Should NOT list README.md
```

**Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add .chezmoi.toml.tmpl .chezmoiignore
git commit -m "feat: add chezmoi config with per-machine prompts and OS-conditional ignore"
```

---

### Task 8: Write README

The README lives in the chezmoi source repo and explains how the system works.

**Files:**
- Create: `~/.local/share/chezmoi/README.md`

**Step 1: Write README**

Write to `~/.local/share/chezmoi/README.md`:

```markdown
# Dotfiles

Dotfiles managed by [chezmoi](https://www.chezmoi.io/). Supports macOS and Linux.

## Quick Start

### New machine setup

```bash
# Install chezmoi and apply dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jraab
```

You'll be prompted for your name and email (used in `.gitconfig`).

### Existing machine

```bash
chezmoi update
```

## Daily Workflow

| Command | What it does |
|---------|-------------|
| `chezmoi edit ~/.bashrc` | Edit the source template for .bashrc |
| `chezmoi diff` | Preview what would change |
| `chezmoi apply` | Apply changes to home directory |
| `chezmoi update` | Pull from GitHub + apply |
| `chezmoi add ~/.<file>` | Start managing a new dotfile |
| `chezmoi cd` | cd into the source directory |

## Structure

```
dot_bash_profile.tmpl       → ~/.bash_profile (templated for conda paths)
dot_bashrc.tmpl             → ~/.bashrc (sources modular config below)
dot_vimrc                   → ~/.vimrc
dot_gitconfig.tmpl          → ~/.gitconfig (templated for name/email)
private_dot_config/bash/
  core                      → ~/.config/bash/core (PATH, exports, history)
  aliases                   → ~/.config/bash/aliases (ll, longleaf, etc.)
  macos                     → ~/.config/bash/macos (colors, Homebrew)
  linux                     → ~/.config/bash/linux (colors, ls alias)
  sync-functions            → ~/.config/bash/sync-functions (rsync project sync)
private_dot_claude/
  settings.json             → ~/.claude/settings.json (Claude Code config)
```

## How It Works

- **Modular bash config:** `.bashrc` sources small focused files from `~/.config/bash/`.
  The OS-specific file (`macos` or `linux`) is selected by a chezmoi template.
- **Templates (`.tmpl` files):** Use Go template syntax. `{{ .chezmoi.os }}` detects
  the OS at apply time. `{{ .email }}` comes from `.chezmoi.toml` (set on first init).
- **Exact files:** Files without `.tmpl` are copied as-is.
- **`.chezmoiignore`:** Claude Code settings are skipped on Linux.

## Adding New Dotfiles

```bash
# Add an existing file to chezmoi management
chezmoi add ~/.some-config

# Add as a template (if it needs OS-specific content)
chezmoi add --template ~/.some-config

# Edit, preview, apply
chezmoi edit ~/.some-config
chezmoi diff
chezmoi apply
```

## Machines

- 3x macOS (personal/work) — full config including Claude Code
- 1x Linux server (longleaf at UNC) — shell config only, no Claude Code
```

**Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add README.md
git commit -m "docs: add README with setup instructions and structure reference"
```

---

### Task 9: Verify and apply

Test the full chezmoi setup before going live.

**Step 1: Run chezmoi diff to preview all changes**

```bash
chezmoi diff
```

Review the diff carefully. Key things to check:
- `.bashrc` will change from a symlink to a regular file with new modular content
- `.bash_profile` will be updated with cleaner conda setup
- `.vimrc` will change from a symlink to a regular file (same content)
- `.gitconfig` should be unchanged (or gains the `excludesfile` typo fix)
- `.config/bash/*` files will be created (new)
- `.claude/settings.json` should be unchanged

**Step 2: Dry-run apply**

```bash
chezmoi apply --dry-run --verbose
# Review output - shows what would be created/modified
```

**Step 3: Apply for real**

```bash
chezmoi apply --verbose
```

**Step 4: Verify files are in place**

```bash
# Check key files exist and are regular files (not symlinks)
ls -la ~/.bashrc ~/.bash_profile ~/.vimrc ~/.gitconfig
# Expected: regular files, not symlinks

# Check modular config exists
ls -la ~/.config/bash/
# Expected: core, aliases, macos, linux, sync-functions

# Check Claude settings
ls -la ~/.claude/settings.json
# Expected: regular file

# Quick sanity: source bashrc in a subshell
bash -c 'source ~/.bashrc && echo "OK: bashrc loads"'
```

**Step 5: Commit (nothing to commit in chezmoi repo - just verify)**

```bash
cd ~/.local/share/chezmoi
git status
# Expected: clean working tree
```

---

### Task 10: Clean up old dotfiles repo and push

Retire the old `~/dotfiles` directory and push the new chezmoi source to GitHub.

**Step 1: Remove old symlinks (now replaced by chezmoi-managed files)**

The symlinks were already replaced by `chezmoi apply` in Task 9. Verify:

```bash
file ~/.bashrc ~/.vimrc
# Expected: "ASCII text" (not "symbolic link")
```

**Step 2: Copy the design docs into chezmoi source**

```bash
mkdir -p ~/.local/share/chezmoi/docs/plans
cp ~/dotfiles/docs/plans/*.md ~/.local/share/chezmoi/docs/plans/
```

**Step 3: Commit docs**

```bash
cd ~/.local/share/chezmoi
git add docs/
git commit -m "docs: add design and implementation plans"
```

**Step 4: Force-push to GitHub (replaces old dotfiles repo content)**

```bash
cd ~/.local/share/chezmoi
git push --force origin master
```

**IMPORTANT:** This replaces the old repo content. The old `~/dotfiles` history is preserved in `~/dotfiles/.git` if you ever need it.

**Step 5: Rename/archive old dotfiles directory**

```bash
mv ~/dotfiles ~/dotfiles.old
```

Keep `~/dotfiles.old` around for a week or so, then delete once you're confident in the chezmoi setup.

**Step 6: Verify end-to-end**

```bash
# Verify chezmoi can pull from remote
chezmoi update --dry-run

# Verify managed files
chezmoi managed

# Open a new terminal and verify shell loads correctly
bash -l -c 'echo "PATH=$PATH" && type syncup && echo "All good"'
```
