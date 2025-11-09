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

# Validation and Testing

# Run all validation checks
validate: validate-nix validate-configs validate-syntax
    @echo "✅ All validations passed!"

# Validate Nix flake structure
validate-nix:
    @echo "🔍 Validating Nix flake..."
    nix flake check --show-trace
    @echo "✓ Flake validation passed"

# Validate all Home Manager configurations (build without activating)
validate-configs:
    @echo "🔍 Validating Home Manager configurations..."
    @echo "  Checking user@linux..."
    @nix build --no-link .#homeConfigurations.\"user@linux\".activationPackage
    @echo "  Checking user@darwin-x86..."
    @nix build --no-link .#homeConfigurations.\"user@darwin-x86\".activationPackage
    @echo "  Checking user@darwin-arm..."
    @nix build --no-link .#homeConfigurations.\"user@darwin-arm\".activationPackage
    @echo "✓ All configurations validated"

# Validate Nix syntax and formatting
validate-syntax:
    @echo "🔍 Checking Nix syntax and formatting..."
    @nixpkgs-fmt --check *.nix || (echo "❌ Run 'just format' to fix formatting" && exit 1)
    @echo "✓ Syntax validation passed"

# Validate YAML files (cloud-init, docker-compose, pre-commit)
validate-yaml:
    @echo "🔍 Validating YAML files..."
    @if command -v yamllint > /dev/null; then \
        yamllint -c .yamllint cloud/cloud-init.yaml docker-compose.yml .pre-commit-config.yaml || true; \
    else \
        echo "⚠️  yamllint not found, skipping YAML validation"; \
    fi

# Validate shell scripts
validate-scripts:
    @echo "🔍 Validating shell scripts..."
    @if command -v shellcheck > /dev/null; then \
        shellcheck .devcontainer/setup.sh cloud/setup-vm.sh; \
        echo "✓ Shell script validation passed"; \
    else \
        echo "⚠️  shellcheck not found, skipping script validation"; \
    fi

# Test build for specific configuration
test-config CONFIG:
    @echo "🧪 Testing configuration: {{CONFIG}}"
    @nix build --no-link .#homeConfigurations.\"{{CONFIG}}\".activationPackage
    @echo "✓ Configuration {{CONFIG}} builds successfully"

# Dry-run Home Manager switch (show what would change)
dry-run CONFIG="user@linux":
    @echo "🔍 Dry-run for {{CONFIG}}..."
    home-manager build --flake .#{{CONFIG}} --dry-run

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

# Docker commands

# Build Docker image
docker-build:
    @echo "🐳 Building Docker image..."
    docker build -t nix-dotfiles:latest .

# Run Docker container interactively
docker-run:
    @echo "🐳 Running Docker container..."
    docker run -it --rm \
        -v $(pwd):/workspace \
        -v nix-store:/nix \
        -v home-data:/home/developer \
        nix-dotfiles:latest

# Start with Docker Compose
docker-up:
    @echo "🐳 Starting Docker Compose environment..."
    docker-compose up -d
    @echo "✅ Environment started! Access with: docker-compose exec devenv zsh"

# Stop Docker Compose
docker-down:
    @echo "🐳 Stopping Docker Compose environment..."
    docker-compose down

# Access running Docker Compose container
docker-shell:
    @echo "🐳 Accessing container shell..."
    docker-compose exec devenv zsh

# Show Docker container logs
docker-logs:
    docker-compose logs -f

# Clean Docker resources
docker-clean:
    @echo "🧹 Cleaning Docker resources..."
    docker-compose down -v
    docker rmi nix-dotfiles:latest || true
    @echo "✅ Docker cleanup complete!"

# Cloud VM commands

# Display cloud setup instructions
cloud-info:
    @echo "☁️  Cloud VM Setup Options:"
    @echo ""
    @echo "1. Automated (cloud-init):"
    @echo "   - Edit cloud/cloud-init.yaml with your SSH key and repo URL"
    @echo "   - Use as user-data when launching VM (AWS/GCP/Azure)"
    @echo ""
    @echo "2. Manual setup script:"
    @echo "   - SSH into your VM"
    @echo "   - Run: curl -sSfL <repo-url>/cloud/setup-vm.sh | bash"
    @echo ""
    @echo "3. Quick one-liner:"
    @echo "   - See README.md for the complete command"
    @echo ""
    @echo "Supported platforms: AWS EC2, GCP, Azure, DigitalOcean, Linode, etc."

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
