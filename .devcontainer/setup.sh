#!/usr/bin/env bash

set -e

echo "🚀 Setting up Nix + Home Manager environment..."

# Install Determinate Nix if not already installed
if ! command -v nix &> /dev/null; then
    echo "📦 Installing Determinate Nix..."

    # In Codespaces/containers, systemd is often not fully active during postCreateCommand
    # Use --init none to skip systemd setup and start daemon manually
    echo "  Installing Nix without systemd integration (for container compatibility)"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
        --no-confirm \
        --init none

    # Source the nix environment for current session
    echo "🔧 Loading Nix environment..."
    set +e  # Temporarily disable exit on error for sourcing
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    set -e

    # Start the Nix daemon manually
    echo "🔧 Starting Nix daemon..."
    if [ -x /nix/var/nix/profiles/default/bin/nix-daemon ]; then
        # Kill any existing daemon first
        sudo pkill -f nix-daemon || true
        # Start daemon in background
        sudo -b /nix/var/nix/profiles/default/bin/nix-daemon
        # Wait for daemon to be ready
        sleep 3
    fi
else
    echo "✓ Nix is already installed"
    # Source the environment
    set +e
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    set -e
    # Make sure daemon is running
    if [ -x /nix/var/nix/profiles/default/bin/nix-daemon ]; then
        sudo pkill -f nix-daemon || true
        sudo -b /nix/var/nix/profiles/default/bin/nix-daemon
        sleep 2
    fi
fi

# Note: Determinate Nix comes with flakes enabled by default, no additional configuration needed!

# Verify Nix is working
echo "🔍 Verifying Nix installation..."
# Source the environment again to ensure it's loaded
set +e
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
set -e

# Try to run nix with a timeout and better error handling
if ! timeout 10 nix --version &> /dev/null; then
    echo "❌ Nix is not responding. Attempting to restart daemon..."
    sudo pkill -f nix-daemon || true
    sleep 1
    sudo -b /nix/var/nix/profiles/default/bin/nix-daemon
    sleep 3

    # Try one more time
    if ! timeout 10 nix --version &> /dev/null; then
        echo "❌ Nix installation failed. Please check the logs above."
        exit 1
    fi
fi
echo "✓ Nix $(nix --version) is ready"

# Apply Home Manager configuration directly
echo "🏠 Setting up Home Manager..."
# Note: We use nix run instead of home-manager init to avoid conflicts
# The flake configuration will handle the installation
nix run home-manager/master -- switch --flake .#user@linux -b backup

# Install Claude Code via npm (if not available in nixpkgs)
echo "🤖 Installing Claude Code..."
if command -v npm &> /dev/null; then
    # Configure npm to use user-local directory for global packages
    # This is necessary because Nix Node.js can't write to /nix/store

    # Fix ownership of npm files if they exist and are owned by root
    if [ -d ~/.npm ]; then
        echo "  Fixing npm cache ownership..."
        sudo chown -R $(id -u):$(id -g) ~/.npm || true
    fi
    if [ -f ~/.npmrc ]; then
        sudo chown $(id -u):$(id -g) ~/.npmrc || true
    fi

    mkdir -p ~/.npm-global
    npm config set prefix ~/.npm-global

    # Add npm global bin to PATH for future shells
    if [ -f ~/.bashrc ]; then
        if ! grep -q "npm-global/bin" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# Add npm global packages to PATH" >> ~/.bashrc
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
        fi
    fi

    # Add to current PATH for this session
    export PATH="$HOME/.npm-global/bin:$PATH"

    # Install Claude Code
    npm install -g @anthropic-ai/claude-code || echo "⚠️  Claude Code installation failed, you can install it later with: npm install -g @anthropic-ai/claude-code"
else
    echo "⚠️  npm not found, Claude Code installation skipped"
    echo "   You can install it manually later with: npm install -g @anthropic-ai/claude-code"
fi

# Set up pre-commit hooks
echo "🔒 Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install || echo "⚠️  Pre-commit hook installation failed, you can set it up later with: pre-commit install"
else
    echo "⚠️  pre-commit not found yet, will be available after restarting shell"
fi

# Ensure Nix is available in future shells
echo "🔧 Configuring shell environment..."
# Add Nix environment to bashrc if not already there
if [ -f ~/.bashrc ]; then
    if ! grep -q "nix-daemon.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Load Nix environment" >> ~/.bashrc
        echo "if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then" >> ~/.bashrc
        echo "    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
    fi
fi

echo "✅ Setup complete! Nix and Home Manager are ready."
echo "   To start using Nix in this terminal, run:"
echo "   source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
echo ""
echo "   For new terminals, Nix will be available automatically."
