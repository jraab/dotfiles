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
dot_bash_profile.tmpl       -> ~/.bash_profile (templated for conda paths)
dot_bashrc.tmpl             -> ~/.bashrc (sources modular config below)
dot_vimrc                   -> ~/.vimrc
dot_gitconfig.tmpl          -> ~/.gitconfig (templated for name/email)
private_dot_config/bash/
  core                      -> ~/.config/bash/core (PATH, exports, history)
  aliases                   -> ~/.config/bash/aliases (ll, longleaf, etc.)
  macos                     -> ~/.config/bash/macos (colors, Homebrew)
  linux                     -> ~/.config/bash/linux (colors, ls alias)
  sync-functions            -> ~/.config/bash/sync-functions (rsync project sync)
private_dot_claude/
  settings.json             -> ~/.claude/settings.json (Claude Code config)
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

- 3x macOS (personal/work) - full config including Claude Code
- 1x Linux server (longleaf at UNC) - shell config only, no Claude Code
