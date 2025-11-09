#!/usr/bin/env bash
# Setup script for Cloud VMs (AWS, GCP, Azure, DigitalOcean, etc.)
# Run this script on a fresh VM to set up the Nix + Home Manager environment

set -e

echo "🚀 Setting up Nix + Home Manager on Cloud VM..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root."
    echo "   Run as a regular user with sudo privileges."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "✓ Detected OS: $OS"
else
    echo "❌ Cannot detect OS"
    exit 1
fi

# Update system packages
echo "📦 Updating system packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential
elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
    sudo dnf install -y curl git gcc gcc-c++ make
elif [ "$OS" = "amzn" ]; then
    sudo yum install -y curl git gcc gcc-c++ make
else
    echo "⚠️  Unsupported OS: $OS"
    echo "   Continuing anyway, but you may need to install dependencies manually"
fi

# Install Determinate Nix
echo "📦 Installing Determinate Nix..."
if ! command -v nix &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --no-confirm

    # Source Nix for current session
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    echo "✓ Nix is already installed"
fi

# Clone dotfiles repository
REPO_URL="${DOTFILES_REPO:-https://github.com/YOUR_USERNAME/nix-dotfiles.git}"
DOTFILES_DIR="$HOME/nix-dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📥 Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    echo "✓ Dotfiles repository already exists"
    cd "$DOTFILES_DIR"
    git pull
fi

cd "$DOTFILES_DIR"

# Install Home Manager
echo "🏠 Installing Home Manager..."
nix run home-manager -- init --switch

# Apply configuration
echo "⚙️  Applying Home Manager configuration..."
home-manager switch --flake .#user@linux

# Install pre-commit hooks
echo "🔒 Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
fi

# Install Claude Code
echo "🤖 Installing Claude Code..."
if command -v npm &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
else
    echo "⚠️  npm not found, skipping Claude Code installation"
fi

# Update shell configuration
if ! grep -q "nix-daemon.sh" "$HOME/.profile" 2>/dev/null; then
    echo "🐚 Updating shell configuration..."
    cat >> "$HOME/.profile" <<'EOF'

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
EOF
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or run: source ~/.profile)"
echo "  2. Verify installation: nix --version"
echo "  3. Check Home Manager: home-manager --version"
echo "  4. Start using your environment!"
echo ""
echo "Configuration location: $DOTFILES_DIR"
echo ""
