# Chezmoi Dotfiles Migration Design

**Date:** 2026-02-12
**Status:** Approved

## Problem

Dotfiles are partially managed across 4 machines (3 macOS, 1 Linux server) with manual symlinks and an ad-hoc `~/dotfiles` git repo. Shell configs have hardcoded macOS paths that break on Linux. Claude Code settings aren't synced at all.

## Approach: Chezmoi + Modular Bash Config

Use chezmoi's templating for OS-specific differences, combined with a modular bash config structure under `~/.config/bash/`.

### Why chezmoi

- Single tool handles file placement, templating, and git sync
- Built-in OS/arch detection via Go templates
- `chezmoi update` = one command to pull + apply on any machine
- No manual symlink management

### Why modular bash

- Each concern lives in its own file (aliases, OS-specific, sync tools)
- Easy to add/remove functionality without touching a monolithic `.bashrc`
- OS-specific files are plain bash (no template syntax to learn)

## Source Directory Structure

```
~/.local/share/chezmoi/           # chezmoi source (backed by git)
├── README.md                     # How this system works
├── .chezmoi.toml.tmpl            # Per-machine config (auto-detected OS)
├── .chezmoiignore                # Skip .claude on Linux
├── dot_bash_profile.tmpl         # Login shell: conda, sources .bashrc
├── dot_bashrc.tmpl               # Interactive shell: sources modular configs
├── dot_vimrc                     # Exact copy, no templating
├── dot_gitconfig.tmpl            # Git identity (templated name/email)
├── private_dot_config/
│   └── bash/
│       ├── core                  # PATH, exports, prompt
│       ├── aliases               # Shared aliases (ll, longleaf, etc.)
│       ├── macos                 # macOS: LSCOLORS, Homebrew
│       ├── linux                 # Linux: LS_COLORS, Linux paths
│       └── sync-functions        # rsync project sync tooling
└── private_dot_claude/
    ├── settings.json             # Claude Code settings
    └── plugins/
        └── installed_plugins.json
```

## File Decisions

| File | chezmoi type | Reason |
|------|-------------|--------|
| `.bashrc` | template | OS detection to source macos vs linux |
| `.bash_profile` | template | Conda path differs per OS |
| `.vimrc` | exact | Identical everywhere |
| `.gitconfig` | template | Name/email might vary per machine |
| `.config/bash/core` | exact | Shared PATH, exports |
| `.config/bash/aliases` | exact | Shared aliases |
| `.config/bash/macos` | exact | macOS-only settings |
| `.config/bash/linux` | exact | Linux-only settings |
| `.config/bash/sync-functions` | exact | rsync tooling |
| `.claude/settings.json` | exact | Same everywhere |
| `.claude/plugins/installed_plugins.json` | exact | Same everywhere |

## .chezmoiignore

Claude Code files are skipped on Linux (not needed on the server):

```
{{ if ne .chezmoi.os "darwin" }}
.claude/**
{{ end }}
```

## Secrets

No secrets in current dotfiles. SSH keys stay in `~/.ssh/` unmanaged. Git config has name/email only.

## Migration

The existing `~/dotfiles` repo and manual symlinks will be retired after migration. Chezmoi manages files as copies (not symlinks).

## Daily Workflow

- Edit: `chezmoi edit ~/.bashrc` or edit source dir directly
- Preview: `chezmoi diff`
- Apply: `chezmoi apply`
- Sync: `chezmoi update` (git pull + apply)
- Add new file: `chezmoi add ~/.some-config`
