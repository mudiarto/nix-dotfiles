#!/usr/bin/env bash

set -e

echo "🚀 Setting up Nix + Home Manager environment..."

# Enable experimental features
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF

# Update channels
echo "📦 Updating Nix channels..."
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update

# Install Home Manager
echo "🏠 Installing Home Manager..."
nix run home-manager/master -- init --switch

# Apply our configuration
echo "⚙️  Applying Home Manager configuration..."
cd /workspace
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
