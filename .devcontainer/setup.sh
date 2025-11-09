#!/usr/bin/env bash

set -e

echo "🚀 Setting up Nix + Home Manager environment..."

# Install Determinate Nix if not already installed
if ! command -v nix &> /dev/null; then
    echo "📦 Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
        --init none \
        --no-confirm

    # Source the nix environment for current session
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    echo "✓ Nix is already installed"
fi

# Note: Determinate Nix comes with flakes enabled by default, no additional configuration needed!

# Install Home Manager
echo "🏠 Installing Home Manager..."
nix run home-manager/master -- init --switch

# Apply our configuration
echo "⚙️  Applying Home Manager configuration..."
# Note: postCreateCommand runs from the workspace directory by default
home-manager switch --flake .#user@linux

# Install Claude Code via npm (if not available in nixpkgs)
echo "🤖 Installing Claude Code..."
if command -v npm &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
else
    echo "⚠️  npm not found, Claude Code installation skipped"
    echo "   You can install it manually later with: npm install -g @anthropic-ai/claude-code"
fi

# Set up pre-commit hooks
echo "🔒 Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
fi

# Change default shell to zsh
echo "🐚 Setting up zsh..."
if [ -f ~/.nix-profile/bin/zsh ]; then
    echo "Zsh installed successfully"
fi

echo "✅ Setup complete! Please restart your terminal or run 'source ~/.zshrc'"
