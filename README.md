# OMARCHY LIKE

This script sets up an Omarchy-like terminal experience on Ubuntu/Debian.
It installs CLI tools, TUI applications, and configures your shell.

Safe to run multiple times - skips already installed packages.
Automatically detects CPU architecture (x86_64 or ARM64).

## Install and Run

```bash
curl -fsSL https://raw.githubusercontent.com/Albrrak773/omarchy-like/main/omarchy-like.sh -o omarchy-like.sh
chmod +x omarchy-like.sh
./omarchy-like.sh
```

## Usage

After installation, activate the new shell configuration:

```bash
source ~/.bashrc
```

## Uninstall

To remove everything installed by this script:

```bash
curl -fsSL https://raw.githubusercontent.com/Albrrak773/omarchy-like/main/purge.sh -o purge.sh
chmod +x purge.sh
./purge.sh
```

## CLI TOOLS

- **eza** - Modern ls replacement with icons, colors, git status, tree view
- **zoxide** - Smart cd command that remembers frequently used directories
- **starship** - Fast, customizable cross-shell prompt
- **fzf** - Command-line fuzzy finder for searching files/history
- **bat** - Cat clone with syntax highlighting and git integration
- **ripgrep** - Fast grep alternative (rg command)
- **fd-find** - Fast find alternative (fd command)
- **neovim** - Hyperextensible Vim-based editor
- **git** - Version control system
- **curl** - Data transfer utility
- **opencode** - AI-powered coding assistant CLI

## TUI APPLICATIONS

- **btop** - System resource monitor (CPU, RAM, disks, network, processes)
- **lazygit** - Simple terminal UI for git commands
- **lazydocker** - Simple terminal UI for docker management

## CONFIG FILES

- `~/.bashrc` - Shell configuration with aliases and functions
- `~/.config/starship.toml` - Prompt styling configuration
- `~/.config/nvim/` - Neovim configuration (LazyVim)
- `~/.config/btop/` - Btop configuration
- `~/.config/opencode/` - OpenCode AI assistant configuration
