# Claude Code - Nix Dotfiles Repository

This repository uses Nix + Home Manager to provide a consistent development environment across multiple platforms (macOS, Linux, GitHub Codespaces, and cloud environments).

**Note:** This repository uses **Determinate Nix** (from Determinate Systems) instead of the standard Nix installer. Determinate Nix provides:
- Flakes and nix-command enabled by default
- Better installation and uninstallation experience
- Improved error messages and diagnostics
- Consistent behavior across platforms

## Repository Overview

This is a dotfiles repository that manages:
- Shell configuration (Zsh)
- Development tools (Git, Just, Neovim, Tmux, Docker)
- Language toolchains (Node.js, Python, Rust, Go)
- Security tools (pre-commit hooks, secret detection)

## Project Structure

```
.
├── flake.nix                  # Nix flake configuration (entry point)
├── home.nix                   # Home Manager configuration (main config)
├── Justfile                   # Command runner with helpful tasks
├── .devcontainer/             # GitHub Codespaces configuration
│   ├── devcontainer.json      # Devcontainer settings
│   └── setup.sh               # Post-create setup script
├── cloud/                     # Cloud VM deployment configs
│   ├── cloud-init.yaml        # Cloud-init configuration
│   └── setup-vm.sh            # Manual VM setup script
├── docs/                      # Documentation
│   └── nix.md                 # Nix beginner's guide
├── Dockerfile                 # Docker image for containerized env
├── docker-compose.yml         # Docker Compose configuration
├── .pre-commit-config.yaml    # Pre-commit hooks for security
├── .gitignore                 # Git ignore patterns (includes secrets)
├── CLAUDE.md                  # This file
└── README.md                  # User documentation
```

## Key Components

### Nix Configuration (`flake.nix`)
- Defines inputs (nixpkgs, home-manager)
- Supports multiple systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- Provides Home Manager configurations for different platforms
- Includes development shell for managing the repository

### Home Manager Configuration (`home.nix`)
- Manages user packages and dotfiles
- Configures programs: Zsh, Git, Neovim, Tmux, etc.
- Platform-aware configuration (Linux vs macOS)
- Declarative package installation

### Security Features
- Pre-commit hooks with gitleaks for secret detection
- Git-secrets integration
- Comprehensive .gitignore for sensitive files
- Automatic checks before commits

### Deployment Options

This repository supports multiple deployment methods:

**1. GitHub Codespaces** (`.devcontainer/`)
- Automatic setup via devcontainer.json
- Uses Debian base image with Determinate Nix
- Post-create script handles Home Manager installation

**2. Docker** (`Dockerfile`, `docker-compose.yml`)
- Containerized environment for testing or local development
- Persistent volumes for Nix store and home data
- Useful when you can't install Nix directly
- Commands: `just docker-build`, `just docker-up`, `just docker-shell`

**3. Cloud VMs** (`cloud/`)
- **cloud-init.yaml**: Automated setup for AWS, GCP, Azure, DigitalOcean
- **setup-vm.sh**: Manual setup script for existing VMs
- Supports all major cloud providers
- Use with terraform, ansible, or manual provisioning

**4. Local Installation**
- Direct installation via Determinate Nix
- Platform-specific configurations (Linux, macOS Intel, macOS ARM)
- Commands: `just bootstrap-linux`, `just bootstrap-darwin`

## Common Tasks

### Adding a New Package
1. Edit `home.nix`
2. Add package to `home.packages` list
3. Run `home-manager switch --flake .#<config>`
4. Commit changes

### Modifying Program Configuration
1. Edit the relevant `programs.*` section in `home.nix`
2. Apply changes with `home-manager switch`
3. Test the configuration
4. Commit changes

### Adding Platform-Specific Configuration
1. Use `lib.mkIf (platform == "linux")` or `lib.mkIf (platform == "darwin")`
2. Add platform-specific packages or settings
3. Test on both platforms if possible

### Updating Dependencies
```bash
nix flake update
home-manager switch --flake .#<config>
```

## Development Workflow

1. Make changes to configuration files
2. Test locally: `home-manager switch --flake .#user@linux`
3. Pre-commit hooks will run automatically on commit
4. Push changes to repository
5. Other machines can pull and apply: `home-manager switch --flake .#<config>`

## Testing and Validation

### Quick Validation Commands

```bash
# Validate all configurations
just validate

# Individual checks
just validate-nix      # Check flake structure
just validate-configs  # Build all Home Manager configs
just validate-syntax   # Check Nix formatting
just validate-scripts  # Validate shell scripts
just validate-yaml     # Validate YAML files
```

### Before Committing

Always run these checks before committing changes:

```bash
# Validate Nix configurations
nix flake check --show-trace

# Build without activating to test
nix build .#homeConfigurations."user@linux".activationPackage

# Check formatting
nixpkgs-fmt --check *.nix

# Run pre-commit hooks manually
pre-commit run --all-files
```

### Testing Specific Configurations

```bash
# Test a specific config
just test-config "user@darwin-arm"

# Dry-run to see what would change
just dry-run user@linux

# Build without linking (doesn't pollute working directory)
nix build --no-link .#homeConfigurations."user@darwin-x86".activationPackage
```

### CI/CD

The repository includes GitHub Actions workflows (`.github/workflows/ci.yml`) that:
- Validate all Nix flake configurations
- Build all Home Manager configurations (Linux, macOS Intel, macOS ARM)
- Check Nix formatting
- Validate shell scripts with shellcheck
- Validate YAML files with yamllint
- Test Docker builds
- Run security scans (pre-commit hooks)

These checks run automatically on:
- Pull requests to main/master
- Pushes to main/master
- Manual workflow dispatch

### Local Testing

```bash
# Test Docker build locally
just docker-build

# Test in isolated Docker environment
just docker-up
just docker-shell
# Make changes and test inside container
exit
just docker-down
```

## Important Notes

### Secret Management
- Never commit secrets to this repository
- Pre-commit hooks will detect common secret patterns
- Use environment variables or external secret management tools
- Review .gitignore regularly

### Customization Points
- Git user name/email in `home.nix` (search for TODO)
- Platform-specific settings
- Shell aliases and functions
- Neovim plugins and configuration

### Platform Differences
- macOS uses different paths for some tools
- Docker behavior differs on macOS (Docker Desktop vs native)
- Some packages may not be available on all platforms

## Debugging

### Home Manager Issues
```bash
# Check what will be built
home-manager build --flake .#<config>

# Verbose output
home-manager switch --flake .#<config> --show-trace

# Check Home Manager generations
home-manager generations
```

### Nix Issues
```bash
# Check flake
nix flake check

# Update flake inputs
nix flake update

# Show flake outputs
nix flake show
```

### Pre-commit Issues
```bash
# Run hooks manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean
```

## Getting Help

### Documentation in This Repo

- **docs/nix.md**: Comprehensive beginner's guide to Nix operations
  - Installing packages, services, custom scripts
  - Troubleshooting common issues
  - Learning resources

### External Resources

- Determinate Nix: https://github.com/DeterminateSystems/nix-installer
- Nix documentation: https://nixos.org/manual/nix/stable/
- Home Manager manual: https://nix-community.github.io/home-manager/
- Home Manager options: https://mipmip.github.io/home-manager-option-search/

## Tips for Claude

When working on this repository:

1. **Always validate changes**: Run `just validate` before committing to catch issues early
2. **Test all platforms**: Use `just validate-configs` to build Linux and macOS configurations
3. **Platform awareness**: Consider both Linux and macOS when making changes
4. **Security first**: Never suggest committing secrets or bypassing pre-commit hooks
5. **Documentation**: Update this file and README.md when making significant changes
6. **Incremental changes**: Test one change at a time, especially for complex configurations
7. **Use Nix search**: Search for packages at https://search.nixos.org/packages
8. **Check compatibility**: Some packages may not work on all platforms
9. **Docker testing**: Use `just docker-build` and `just docker-up` to test changes in isolation
10. **Cloud deployment**: Remember to update cloud/cloud-init.yaml when making significant changes
11. **CI integration**: Check GitHub Actions workflows after pushing changes

### Working with Docker
- Test Dockerfile builds after modifying dependencies
- Update docker-compose.yml resource limits based on requirements
- Ensure volumes are properly configured for persistence

### Working with Cloud Deployments
- Test cloud-init.yaml syntax with `cloud-init devel schema -c cloud/cloud-init.yaml`
- Remember to update setup-vm.sh when changing the installation process
- Consider cloud provider differences (systemd vs init)

## Current Limitations

- Claude Code is installed via npm (not yet available in nixpkgs)
- Docker build can be slow on first run (downloads Nix packages)
- Some GUI applications may need additional configuration on different platforms
- First-time setup can be slow due to package downloads
- Cloud-init requires editing before use (SSH keys, repo URL)

## Future Enhancements

- [ ] Add NixOS system configuration
- [ ] Create separate modules for different tool categories
- [ ] Add CI/CD for testing configurations
- [ ] Create platform-specific optimization
- [ ] Add more pre-configured development environments (via direnv)
