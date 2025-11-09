# Justfile for nix-dotfiles
# Run `just --list` to see all available commands

# Default recipe to display help
default:
    @just --list

# Apply Home Manager configuration for Linux
apply-linux:
    home-manager switch --flake .#user@linux

# Apply Home Manager configuration for macOS Intel
apply-darwin-x86:
    home-manager switch --flake .#user@darwin-x86

# Apply Home Manager configuration for macOS Apple Silicon
apply-darwin-arm:
    home-manager switch --flake .#user@darwin-arm

# Build configuration without activating
build CONFIG="user@linux":
    home-manager build --flake .#{{CONFIG}}

# Update flake inputs
update:
    nix flake update

# Check flake for errors
check:
    nix flake check

# Show flake outputs
show:
    nix flake show

# Format Nix files
format:
    nixpkgs-fmt *.nix

# List Home Manager generations
generations:
    home-manager generations

# Run pre-commit hooks on all files
pre-commit:
    pre-commit run --all-files

# Install pre-commit hooks
install-hooks:
    pre-commit install

# Update pre-commit hooks
update-hooks:
    pre-commit autoupdate

# Clean pre-commit cache
clean-hooks:
    pre-commit clean

# Search for a package
search PACKAGE:
    nix search nixpkgs {{PACKAGE}}

# Install Claude Code via npm
install-claude:
    npm install -g @anthropic-ai/claude-code

# Show system info
info:
    @echo "System: $(uname -s)"
    @echo "Architecture: $(uname -m)"
    @echo "Nix version: $(nix --version)"
    @echo "Home Manager: $(home-manager --version || echo 'not installed')"

# Clean build artifacts
clean:
    rm -rf result result-*

# Run development shell
dev:
    nix develop

# Test configuration (build without activating)
test CONFIG="user@linux":
    @echo "Testing configuration: {{CONFIG}}"
    home-manager build --flake .#{{CONFIG}}
    @echo "Build successful! Configuration is valid."

# Bootstrap on a new machine (Linux)
bootstrap-linux:
    @echo "Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    @echo "Note: Determinate Nix enables flakes by default!"
    @echo "Applying configuration..."
    nix run home-manager -- switch --flake .#user@linux
    @echo "Installing pre-commit hooks..."
    pre-commit install
    @echo "Bootstrap complete!"

# Bootstrap on a new machine (macOS)
bootstrap-darwin:
    @echo "Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    @echo "Note: Determinate Nix enables flakes by default!"
    @echo "Please run 'just apply-darwin-x86' or 'just apply-darwin-arm' based on your Mac"
    @echo "Then run 'just install-hooks'"

# Show documentation
docs:
    @echo "📚 Documentation Files:"
    @echo "  - README.md: User documentation and setup instructions"
    @echo "  - CLAUDE.md: Documentation for Claude AI assistant"
    @echo ""
    @echo "📖 Online Resources:"
    @echo "  - Nix Manual: https://nixos.org/manual/nix/stable/"
    @echo "  - Home Manager: https://nix-community.github.io/home-manager/"
    @echo "  - Package Search: https://search.nixos.org/packages"
    @echo "  - Options Search: https://mipmip.github.io/home-manager-option-search/"
