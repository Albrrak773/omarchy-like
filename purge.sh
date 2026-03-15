#!/bin/bash
#
# ============================================================================
#                               OMARCHY-LIKE PURGE
# ============================================================================
#
# This script removes everything installed by omarchy-like.sh
# WARNING: This will delete all configs including neovim configs!
#
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}    OMARCHY-LIKE PURGE SCRIPT${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This will remove:${NC}"
echo "  • apt packages: eza, zoxide, fzf, bat, ripgrep, fd-find, btop"
echo "  • snap: neovim (nvim)"
echo "  • binaries: starship, lazygit, lazydocker, opencode"
echo "  • configs: ~/.config/{starship,btop,opencode,nvim}"
echo "  • bashrc omarchy-like section"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# ============================================================================
# REMOVE APT PACKAGES
# ============================================================================

APT_PACKAGES=(eza zoxide fzf bat ripgrep fd-find btop)

log_info "Removing apt packages..."
for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg -l "$pkg" &> /dev/null; then
        log_info "Removing $pkg..."
        sudo apt remove -y "$pkg" 2>/dev/null || log_warn "Could not remove $pkg"
    else
        log_info "$pkg not installed, skipping"
    fi
done

# ============================================================================
# REMOVE BINARIES
# ============================================================================

log_info "Removing installed binaries..."

sudo rm -f /usr/local/bin/starship && log_success "Removed starship"
sudo rm -f /usr/local/bin/lazygit && log_success "Removed lazygit"
sudo rm -f /usr/local/bin/lazydocker && log_success "Removed lazydocker"
sudo rm -f /usr/local/bin/fd && log_success "Removed fd symlink"
sudo rm -f /usr/local/bin/bat && log_success "Removed bat symlink"

# ============================================================================
# REMOVE NEOVIM (snap)
# ============================================================================

log_info "Removing neovim..."
if snap list nvim &> /dev/null; then
    sudo snap remove nvim && log_success "Removed neovim snap"
else
    log_info "neovim snap not installed"
fi

# ============================================================================
# REMOVE OPENCODE
# ============================================================================

log_info "Removing opencode..."
rm -rf ~/.opencode && log_success "Removed opencode"

# ============================================================================
# REMOVE CONFIG FILES
# ============================================================================

log_info "Removing config files..."

rm -f ~/.config/starship.toml && log_success "Removed starship config"
rm -rf ~/.config/btop && log_success "Removed btop config"
rm -rf ~/.config/opencode && log_success "Removed opencode config"
rm -rf ~/.config/nvim && log_success "Removed neovim config"

# ============================================================================
# REMOVE BASHRC SECTION
# ============================================================================

log_info "Removing bashrc configuration..."

if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%s)
    
    if grep -q "OMARCHY-LIKE SHELL CONFIGURATION" ~/.bashrc 2>/dev/null; then
        sed -i '/# OMARCHY-LIKE SHELL CONFIGURATION/,/# END OMARCHY-LIKE SHELL CONFIGURATION/d' ~/.bashrc
        log_success "Removed bashrc configuration section"
    fi
    
    sed -i '/starship/d' ~/.bashrc
    sed -i '/zoxide/d' ~/.bashrc
    sed -i '/alias cd="z"/d' ~/.bashrc
    sed -i '/# EZA/,/^fi$/d' ~/.bashrc
    sed -i '/# ZOXIDE/,/^fi$/d' ~/.bashrc
    sed -i '/# FZF/,/^fi$/d' ~/.bashrc
    sed -i '/# DIRECTORY NAVIGATION/,/^alias \.\.\.\.\.\.\./d' ~/.bashrc
    sed -i '/# TOOLS/,/^n()/d' ~/.bashrc
    sed -i '/^n() {/,/^}$/d' ~/.bashrc
    sed -i '/alias lg=/d' ~/.bashrc
    sed -i '/alias ld=/d' ~/.bashrc
    sed -i '/alias g=/d' ~/.bashrc
    sed -i '/alias gcm=/d' ~/.bashrc
    sed -i '/alias gcam=/d' ~/.bashrc
    sed -i '/alias c=/d' ~/.bashrc
    sed -i '/alias ls=.*eza/d' ~/.bashrc
    sed -i '/alias lsa=/d' ~/.bashrc
    sed -i '/alias lt=.*eza/d' ~/.bashrc
    sed -i '/alias lta=/d' ~/.bashrc
    sed -i '/alias ff=/d' ~/.bashrc
    sed -i '/alias eff=/d' ~/.bashrc
    sed -i '/alias \.\.=/d' ~/.bashrc
    sed -i '/alias \.\.\.=/d' ~/.bashrc
    
    log_success "Cleaned bashrc (backup saved)"
else
    log_info "No .bashrc found"
fi

# ============================================================================
# REMOVE LAZY.NVIM DATA
# ============================================================================

log_info "Removing lazy.nvim data..."
rm -rf ~/.local/share/nvim 2>/dev/null && log_success "Removed nvim data"
rm -rf ~/.local/state/nvim 2>/dev/null && log_success "Removed nvim state"
rm -rf ~/.cache/nvim 2>/dev/null && log_success "Removed nvim cache"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         PURGE COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Removed:"
echo "  • apt packages: eza, zoxide, fzf, bat, ripgrep, fd-find, btop"
echo "  • snap: neovim"
echo "  • binaries: starship, lazygit, lazydocker"
echo "  • configs: starship, btop, opencode, nvim"
echo "  • ~/.opencode"
echo "  • bashrc omarchy-like section"
echo "  • nvim data/state/cache"
echo ""
echo "Run 'source ~/.bashrc' to reload your shell."
echo ""
