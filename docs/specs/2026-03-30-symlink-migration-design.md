# Dotfile Management: Chezmoi to Symlink Migration

## Problem

Chezmoi enforces one-way sync (source → home). Editing dotfiles in-place — the natural workflow — risks losing changes on `chezmoi apply`. Merging upstream changes into templates is fragile. The templating features (OS-conditional logic) are only used in two files and can be replaced with runtime detection.

## Decision

Replace chezmoi with a symlink-based approach. The `~/dotfiles/` repo contains the canonical files. An install script creates symlinks from the home directory into the repo. Editing files in either location is the same operation — no sync, no overwrite risk.

Claude skills (`~/.claude/skills`) are managed independently via `claude-sync` and are not part of this repo.

## Repo Structure

```
~/dotfiles/
├── bashrc                  # symlinked to ~/.bashrc
├── bash_profile            # symlinked to ~/.bash_profile
├── config/
│   └── bash/               # symlinked as directory to ~/.config/bash
│       ├── core
│       ├── aliases
│       ├── macos
│       ├── linux
│       └── sync-functions
├── gitconfig               # symlinked to ~/.gitconfig
├── gitignore               # symlinked to ~/.gitignore
├── inputrc                 # symlinked to ~/.inputrc
├── vimrc                   # symlinked to ~/.vimrc
├── install.sh              # creates all symlinks
├── docs/
│   └── specs/              # design docs (not symlinked)
└── README.md
```

## File Mapping

| Repo path | Symlink target |
|-----------|---------------|
| `bashrc` | `~/.bashrc` |
| `bash_profile` | `~/.bash_profile` |
| `config/bash/` | `~/.config/bash` (directory symlink) |
| `gitconfig` | `~/.gitconfig` |
| `gitignore` | `~/.gitignore` |
| `inputrc` | `~/.inputrc` |
| `vimrc` | `~/.vimrc` |

## Install Script Behavior

`install.sh` does the following:

1. For each file/directory in the mapping:
   - If target is already a symlink pointing to the right place: skip
   - If target is a real file/directory: move to `~/.dotfiles_old/` as backup
   - Create the symlink
2. Ensure `~/.config/` exists before creating the `bash` directory symlink
3. Report what it did

The script is idempotent — safe to re-run.

## Template Conversion

### bashrc

Replace chezmoi template directives with runtime OS detection:

```bash
if [[ "$(uname)" == "Darwin" ]]; then
    [[ -f ~/.config/bash/macos ]] && source ~/.config/bash/macos
else
    [[ -f ~/.config/bash/linux ]] && source ~/.config/bash/linux
fi
```

### bash_profile

Replace chezmoi OS conditional with a unified conda block that checks all possible paths:

```bash
# Conda - check all common install locations
for conda_sh in \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/anaconda3/etc/profile.d/conda.sh"; do
    if [[ -f "$conda_sh" ]]; then
        source "$conda_sh"
        break
    fi
done
```

### gitconfig

Hardcode name/email (not secret, single user):

```
[user]
    name = Jesse Raab
    email = jesse.r.raab@gmail.com
```

### All files

Remove "Managed by chezmoi" comments. Replace with "Managed by ~/dotfiles" or remove entirely.

## Workflow Changes

### dotpush (in aliases)

Before (chezmoi):
```bash
dotpush() {
    local msg="${1:-update dotfiles}"
    chezmoi apply && \
    git -C "$(chezmoi source-path)" add -A && \
    git -C "$(chezmoi source-path)" commit -m "$msg" && \
    git -C "$(chezmoi source-path)" push
}
```

After (symlinks):
```bash
dotpush() {
    local msg="${1:-update dotfiles}"
    git -C ~/dotfiles add -A && \
    git -C ~/dotfiles commit -m "$msg" && \
    git -C ~/dotfiles push
}
```

### dotpull (new)

```bash
dotpull() {
    git -C ~/dotfiles pull
}
```

### dotcd alias

```bash
alias dotcd='cd ~/dotfiles'
```

### claude-sync

Remove the `chezmoi update` call from the `pull` action. The rest stays the same — it manages skills independently.

## Migration Steps

1. Build new repo contents from current chezmoi source + live files
2. Convert templates to plain files with runtime detection
3. Update aliases (dotpush, dotpull, dotcd)
4. Update claude-sync to remove chezmoi dependency
5. Run install.sh to create symlinks (backs up existing files)
6. Verify: source bashrc, check symlinks, test git
7. Remove chezmoi: `brew uninstall chezmoi`, clean up `~/.local/share/chezmoi/`, `~/.config/chezmoi/`
8. Push to `main` on GitHub
9. On other machines: clone, run install.sh

## Out of Scope

- Claude skills management (stays as separate `claude-sync` workflow)
- Claude Code settings (`~/.claude/settings.json`) — not managed by dotfiles
- Any new dotfiles not currently managed
