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
├── .devcontainer/             # GitHub Codespaces configuration
│   ├── devcontainer.json      # Devcontainer settings
│   └── setup.sh               # Post-create setup script
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

- Determinate Nix: https://github.com/DeterminateSystems/nix-installer
- Nix documentation: https://nixos.org/manual/nix/stable/
- Home Manager manual: https://nix-community.github.io/home-manager/
- Home Manager options: https://mipmip.github.io/home-manager-option-search/

## Tips for Claude

When working on this repository:

1. **Always test changes**: Use `nix flake check` before committing
2. **Platform awareness**: Consider both Linux and macOS when making changes
3. **Security first**: Never suggest committing secrets or bypassing pre-commit hooks
4. **Documentation**: Update this file and README.md when making significant changes
5. **Incremental changes**: Test one change at a time, especially for complex configurations
6. **Use Nix search**: Search for packages at https://search.nixos.org/packages
7. **Check compatibility**: Some packages may not work on all platforms

## Current Limitations

- Claude Code is installed via npm (not yet available in nixpkgs)
- Docker requires platform-specific setup
- Some GUI applications may need additional configuration on different platforms
- First-time setup can be slow due to package downloads

## Future Enhancements

- [ ] Add NixOS system configuration
- [ ] Create separate modules for different tool categories
- [ ] Add CI/CD for testing configurations
- [ ] Create platform-specific optimization
- [ ] Add more pre-configured development environments (via direnv)
