#!/usr/bin/env bash
# setup-zsh.sh — One-shot zsh environment setup for Ubuntu/Debian
#
# Installs: zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting,
#           fzf, zoxide, atuin
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/nyldn/openclaw-admin/main/scripts/setup-zsh.sh | bash
#   # or
#   bash setup-zsh.sh

set -euo pipefail

echo "=== zsh environment setup ==="
echo ""

# --- 1. Install zsh ---
if ! command -v zsh &>/dev/null; then
    echo "[1/7] Installing zsh..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq zsh
else
    echo "[1/7] zsh already installed"
fi

# --- 2. Powerlevel10k ---
P10K_DIR="${HOME}/.powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "[2/7] Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "[2/7] Powerlevel10k already installed"
fi

# --- 3. zsh-autosuggestions ---
ZAS_DIR="${HOME}/.zsh/zsh-autosuggestions"
if [[ ! -d "$ZAS_DIR" ]]; then
    echo "[3/7] Installing zsh-autosuggestions..."
    mkdir -p "${HOME}/.zsh"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZAS_DIR"
else
    echo "[3/7] zsh-autosuggestions already installed"
fi

# --- 4. zsh-syntax-highlighting ---
ZSH_DIR="${HOME}/.zsh/zsh-syntax-highlighting"
if [[ ! -d "$ZSH_DIR" ]]; then
    echo "[4/7] Installing zsh-syntax-highlighting..."
    mkdir -p "${HOME}/.zsh"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_DIR"
else
    echo "[4/7] zsh-syntax-highlighting already installed"
fi

# --- 5. fzf ---
if ! command -v fzf &>/dev/null; then
    echo "[5/7] Installing fzf..."
    git clone --depth=1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    "${HOME}/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
else
    echo "[5/7] fzf already installed"
fi

# --- 6. zoxide ---
if ! command -v zoxide &>/dev/null; then
    echo "[6/7] Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
else
    echo "[6/7] zoxide already installed"
fi

# --- 7. atuin ---
if ! command -v atuin &>/dev/null; then
    echo "[7/7] Installing atuin..."
    curl -sSfL https://setup.atuin.sh | bash
else
    echo "[7/7] atuin already installed"
fi

# --- Configure .zshrc ---
ZSHRC="${HOME}/.zshrc"
MARKER="# --- setup-zsh.sh ---"

if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo ""
    echo "Configuring .zshrc..."

    # Back up existing .zshrc
    [[ -f "$ZSHRC" ]] && cp "$ZSHRC" "${ZSHRC}.bak.$(date +%s)"

    cat >> "$ZSHRC" << 'ZSHRC_BLOCK'

# --- setup-zsh.sh ---

# Powerlevel10k instant prompt (keep near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Theme
source ~/.powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf (Ctrl-R history, Ctrl-T files, Alt-C cd)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# zoxide (use `z` instead of `cd`)
eval "$(zoxide init zsh)"

# atuin (searchable shell history)
eval "$(atuin init zsh)"

# --- end setup-zsh.sh ---
ZSHRC_BLOCK

    echo "   .zshrc updated"
else
    echo ""
    echo ".zshrc already configured (marker found)"
fi

# --- Set zsh as default shell ---
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(command -v zsh)"
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    echo ""
    echo "Setting zsh as default shell..."
    chsh -s "$ZSH_PATH"
    echo "   Default shell changed to $ZSH_PATH"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Open a new terminal or run: exec zsh"
echo "Then run: p10k configure"
