#!/bin/bash
#
# ============================================================================
#                               OMARCHY LIKE
# ============================================================================
#
# This script sets up an Omarchy-like terminal experience on Ubuntu/Debian.
# It installs CLI tools, TUI applications, and configures your shell.
#
# Safe to run multiple times - skips already installed packages.
# Automatically detects CPU architecture (x86_64 or ARM64).
#
# ----------------------------------
# CLI TOOLS
# ----------------------------------
# eza        - Modern ls replacement with icons, colors, git status, tree view
# zoxide     - Smart cd command that remembers frequently used directories
# starship   - Fast, customizable cross-shell prompt
# fzf        - Command-line fuzzy finder for searching files/history
# bat        - Cat clone with syntax highlighting and git integration
# ripgrep    - Fast grep alternative (rg command)
# fd-find    - Fast find alternative (fd command)
# neovim     - Hyperextensible Vim-based editor
# git        - Version control system
# curl       - Data transfer utility
# opencode   - AI-powered coding assistant CLI
#
# ----------------------------------
# TUI APPLICATIONS
# ----------------------------------
# btop       - System resource monitor (CPU, RAM, disks, network, processes)
# lazygit    - Simple terminal UI for git commands
# lazydocker - Simple terminal UI for docker management
#
# ----------------------------------
# CONFIG FILES
# ----------------------------------
# ~/.bashrc            - Shell configuration with aliases and functions
# ~/.config/starship.toml - Prompt styling configuration
# ~/.config/nvim/      - Neovim configuration (LazyVim)
# ~/.config/btop/      - Btop configuration
# ~/.config/opencode/  - OpenCode AI assistant configuration
#
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

declare -a VERIFIED_INSTALLED
declare -a VERIFIED_FAILED

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" &> /dev/null
}

verify_binary() {
    local cmd="$1"
    local path
    
    path=$(command -v "$cmd" 2>/dev/null)
    if [ -z "$path" ]; then
        return 1
    fi
    
    if [ ! -x "$path" ]; then
        return 1
    fi
    
    case "$cmd" in
        nvim)
            timeout 3 "$cmd" --version &> /dev/null
            return $?
            ;;
        starship)
            timeout 5 "$cmd" --version &> /dev/null
            return $?
            ;;
        btop)
            timeout 5 "$cmd" --version &> /dev/null
            return $?
            ;;
        lazygit|lazydocker)
            timeout 5 "$cmd" --version &> /dev/null
            return $?
            ;;
        opencode)
            timeout 5 "$cmd" --version &> /dev/null
            return $?
            ;;
        *)
            timeout 5 "$cmd" --version &> /dev/null || timeout 5 "$cmd" --help &> /dev/null
            return $?
            ;;
    esac
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

get_github_arch() {
    case "$ARCH" in
        x86_64) echo "x86_64" ;;
        arm64)  echo "arm64" ;;
        armv7)  echo "armv7" ;;
        *) echo "$ARCH" ;;
    esac
}

ARCH=$(detect_arch)
GITHUB_ARCH=$(get_github_arch)
log_info "Detected architecture: $ARCH"

# ============================================================================
# PACKAGE INSTALLATION VIA APT
# ============================================================================

log_info "Updating package lists..."
sudo apt update

APT_PACKAGES=(
    "git:git"
    "curl:curl"
    "wget:wget"
    "eza:eza"
    "zoxide:zoxide"
    "fzf:fzf"
    "bat:batcat"
    "ripgrep:rg"
    "fd-find:fdfind"
    "neovim:nvim"
    "btop:btop"
)

log_info "Installing apt packages..."
for entry in "${APT_PACKAGES[@]}"; do
    pkg="${entry%%:*}"
    cmd="${entry##*:}"
    
    if verify_binary "$cmd"; then
        log_success "$pkg already installed and working"
        VERIFIED_INSTALLED+=("$pkg")
    else
        log_info "Installing $pkg..."
        if sudo apt install -y "$pkg"; then
            if verify_binary "$cmd"; then
                log_success "$pkg installed and verified"
                VERIFIED_INSTALLED+=("$pkg")
            else
                log_error "$pkg installed but binary '$cmd' not working"
                VERIFIED_FAILED+=("$pkg")
            fi
        else
            log_error "Failed to install $pkg"
            VERIFIED_FAILED+=("$pkg")
        fi
    fi
done

if command_exists fdfind && ! command_exists fd; then
    log_info "Creating fd symlink..."
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd 2>/dev/null || true
fi

if command_exists batcat && ! command_exists bat; then
    log_info "Creating bat symlink..."
    sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>/dev/null || true
fi

# ============================================================================
# STARSHIP INSTALLATION (official installer)
# ============================================================================

if verify_binary starship; then
    log_success "starship already installed and working"
    VERIFIED_INSTALLED+=("starship")
else
    log_info "Installing starship..."
    if curl -sS https://starship.rs/install.sh | sudo sh; then
        if verify_binary starship; then
            log_success "starship installed and verified"
            VERIFIED_INSTALLED+=("starship")
        else
            log_error "starship installed but verification failed"
            VERIFIED_FAILED+=("starship")
        fi
    else
        log_error "Failed to install starship"
        VERIFIED_FAILED+=("starship")
    fi
fi

# ============================================================================
# LAZYGIT INSTALLATION (from GitHub, architecture-aware)
# ============================================================================

if verify_binary lazygit; then
    log_success "lazygit already installed and working"
    VERIFIED_INSTALLED+=("lazygit")
else
    log_info "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep -Po '"tag_name": "v\K[^"]*' || echo "")
    
    if [ -n "$LAZYGIT_VERSION" ]; then
        LG_ARCH="$GITHUB_ARCH"
        case "$LG_ARCH" in
            x86_64) LG_ARCH="x86_64" ;;
            arm64)  LG_ARCH="arm64" ;;
            armv7)  LG_ARCH="armv6" ;;
        esac
        
        LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LG_ARCH}.tar.gz"
        
        rm -f /tmp/lazygit.tar.gz /tmp/lazygit
        
        if curl -fsSL "$LAZYGIT_URL" -o /tmp/lazygit.tar.gz; then
            if tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit; then
                sudo install -o root -g root -m 0755 /tmp/lazygit /usr/local/bin/lazygit
                rm -f /tmp/lazygit.tar.gz /tmp/lazygit
                
                if verify_binary lazygit; then
                    log_success "lazygit installed and verified (v${LAZYGIT_VERSION} for ${LG_ARCH})"
                    VERIFIED_INSTALLED+=("lazygit")
                else
                    log_error "lazygit installed but verification failed (architecture mismatch?)"
                    VERIFIED_FAILED+=("lazygit")
                fi
            else
                log_error "Failed to extract lazygit (architecture mismatch?)"
                VERIFIED_FAILED+=("lazygit")
                rm -f /tmp/lazygit.tar.gz
            fi
        else
            log_error "Failed to download lazygit from $LAZYGIT_URL"
            VERIFIED_FAILED+=("lazygit")
            rm -f /tmp/lazygit.tar.gz
        fi
    else
        log_error "Failed to get lazygit version from GitHub API"
        VERIFIED_FAILED+=("lazygit")
    fi
fi

# ============================================================================
# LAZYDOCKER INSTALLATION (from GitHub, architecture-aware)
# ============================================================================

if verify_binary lazydocker; then
    log_success "lazydocker already installed and working"
    VERIFIED_INSTALLED+=("lazydocker")
else
    log_info "Installing lazydocker..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" 2>/dev/null | grep -Po '"tag_name": "v\K[^"]*' || echo "")
    
    if [ -n "$LAZYDOCKER_VERSION" ]; then
        LD_ARCH="$GITHUB_ARCH"
        case "$LD_ARCH" in
            x86_64) LD_ARCH="x86_64" ;;
            arm64)  LD_ARCH="arm64" ;;
            armv7)  LD_ARCH="armv6" ;;
        esac
        
        LAZYDOCKER_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LD_ARCH}.tar.gz"
        
        rm -f /tmp/lazydocker.tar.gz /tmp/lazydocker
        
        if curl -fsSL "$LAZYDOCKER_URL" -o /tmp/lazydocker.tar.gz; then
            if tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker; then
                sudo install -o root -g root -m 0755 /tmp/lazydocker /usr/local/bin/lazydocker
                rm -f /tmp/lazydocker.tar.gz /tmp/lazydocker
                
                if verify_binary lazydocker; then
                    log_success "lazydocker installed and verified (v${LAZYDOCKER_VERSION} for ${LD_ARCH})"
                    VERIFIED_INSTALLED+=("lazydocker")
                else
                    log_error "lazydocker installed but verification failed (architecture mismatch?)"
                    VERIFIED_FAILED+=("lazydocker")
                fi
            else
                log_error "Failed to extract lazydocker (architecture mismatch?)"
                VERIFIED_FAILED+=("lazydocker")
                rm -f /tmp/lazydocker.tar.gz
            fi
        else
            log_error "Failed to download lazydocker from $LAZYDOCKER_URL"
            VERIFIED_FAILED+=("lazydocker")
            rm -f /tmp/lazydocker.tar.gz
        fi
    else
        log_error "Failed to get lazydocker version from GitHub API"
        VERIFIED_FAILED+=("lazydocker")
    fi
fi

# ============================================================================
# OPENCODE INSTALLATION (official installer)
# ============================================================================

OPENCODE_PATH="$HOME/.opencode/bin/opencode"

if [ -x "$OPENCODE_PATH" ]; then
    log_success "opencode already installed and working"
    VERIFIED_INSTALLED+=("opencode")
else
    log_info "Installing opencode..."
    if curl -fsSL https://opencode.ai/install | bash; then
        if [ -x "$OPENCODE_PATH" ]; then
            log_success "opencode installed and verified"
            VERIFIED_INSTALLED+=("opencode")
        else
            log_error "opencode installed but binary not found at $OPENCODE_PATH"
            VERIFIED_FAILED+=("opencode")
        fi
    else
        log_error "Failed to install opencode"
        VERIFIED_FAILED+=("opencode")
    fi
fi

# ============================================================================
# CONFIGURATION FILES
# ============================================================================

log_info "Setting up configuration files..."

mkdir -p ~/.config/{nvim,btop,starship,opencode}

cat > ~/.config/starship.toml << 'EOF'
add_newline = true
command_timeout = 200
format = "[$directory$git_branch$git_status]($style)$character"

[character]
error_symbol = "[✗](bold cyan)"
success_symbol = "[❯](bold cyan)"

[directory]
truncation_length = 2
truncation_symbol = "…/"
repo_root_style = "bold cyan"
repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "

[git_branch]
format = "[$branch]($style) "
style = "italic cyan"

[git_status]
format     = '[$all_status]($style)'
style      = "cyan"
ahead      = "⇡${count} "
diverged   = "⇕⇡${ahead_count}⇣${behind_count} "
behind     = "⇣${count} "
conflicted = " "
up_to_date = " "
untracked  = "? "
modified   = " "
stashed    = ""
staged     = ""
renamed    = ""
deleted    = ""
EOF
log_success "starship config created"

cat > ~/.config/btop/btop.conf << 'EOF'
color_theme = "Default"
theme_background = true
truecolor = true
force_tty = false
presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"
vim_keys = true
rounded_corners = true
terminal_sync = true
graph_symbol = "braille"
graph_symbol_cpu = "default"
graph_symbol_gpu = "default"
graph_symbol_mem = "default"
graph_symbol_net = "default"
EOF
log_success "btop config created"

cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "autoupdate": false,
  "formatter": {
    "ruff": { "disabled": true },
    "uv": { "disabled": true }
  }
}
EOF

cat > ~/.config/opencode/tui.json << 'EOF'
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "system"
}
EOF
log_success "opencode config created"

if grep -q "OMARCHY-LIKE SHELL CONFIGURATION" ~/.bashrc 2>/dev/null; then
    log_warn "bashrc already contains omarchy-like config, skipping"
else
    cat >> ~/.bashrc << 'BASHRC_EOF'

# ============================================================================
# OMARCHY-LIKE SHELL CONFIGURATION
# ============================================================================

[[ $- != *i* ]] && return

# ----------------------------------------------------------------------------
# EZA (Modern ls replacement)
# ----------------------------------------------------------------------------
if command -v eza &> /dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
fi

# ----------------------------------------------------------------------------
# ZOXIDE (Smart cd)
# ----------------------------------------------------------------------------
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd="z"
fi

# ----------------------------------------------------------------------------
# FZF (Fuzzy finder)
# ----------------------------------------------------------------------------
if command -v fzf &> /dev/null; then
    alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
    alias eff='$(fzf)'
fi

# ----------------------------------------------------------------------------
# DIRECTORY NAVIGATION
# ----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ----------------------------------------------------------------------------
# TOOLS
# ----------------------------------------------------------------------------
alias lg='lazygit'
alias ld='lazydocker'
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias c='opencode'

n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

# ----------------------------------------------------------------------------
# STARSHIP PROMPT
# ----------------------------------------------------------------------------
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# ============================================================================
# END OMARCHY-LIKE SHELL CONFIGURATION
# ============================================================================
BASHRC_EOF
    log_success "bashrc updated with omarchy-like config"
fi

NVIM_CONFIG_DIR=~/.config/nvim

if [ -d "$NVIM_CONFIG_DIR" ] && [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
    log_warn "neovim config already exists, skipping (backup manually if needed)"
else
    log_info "Setting up LazyVim..."
    
    rm -rf "$NVIM_CONFIG_DIR" 2>/dev/null || true
    mkdir -p "$NVIM_CONFIG_DIR"
    
    cat > "$NVIM_CONFIG_DIR/init.lua" << 'NVIMEOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load LazyVim
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { missing = true },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
NVIMEOF
    
    mkdir -p "$NVIM_CONFIG_DIR/lua/config"
    mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"
    
    log_success "LazyVim bootstrap created (run nvim to complete setup)"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         INSTALLATION COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Architecture:${NC} $ARCH"
echo ""

if [ ${#VERIFIED_INSTALLED[@]} -gt 0 ]; then
    echo -e "${GREEN}Verified and working (${#VERIFIED_INSTALLED[@]}):${NC}"
    for pkg in "${VERIFIED_INSTALLED[@]}"; do
        echo "  ✓ $pkg"
    done
    echo ""
fi

if [ ${#VERIFIED_FAILED[@]} -gt 0 ]; then
    echo -e "${RED}Failed verification (${#VERIFIED_FAILED[@]}):${NC}"
    for pkg in "${VERIFIED_FAILED[@]}"; do
        echo "  ✗ $pkg"
    done
    echo ""
fi

echo "Configuration files created:"
echo "  • ~/.bashrc (shell config)"
echo "  • ~/.config/starship.toml (prompt)"
echo "  • ~/.config/btop/btop.conf (system monitor)"
echo "  • ~/.config/opencode/ (AI assistant)"
echo "  • ~/.config/nvim/ (LazyVim editor)"
echo ""
echo "To activate the new shell config, run:"
echo -e "  ${YELLOW}source ~/.bashrc${NC}"
echo ""
