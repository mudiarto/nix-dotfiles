# Nix Dotfiles

A cross-platform development environment configuration using Nix and Home Manager. Get consistent shell environments, tools, and configurations across macOS, Linux, GitHub Codespaces, and cloud environments.

## Features

- **Cross-platform**: Works on macOS (Intel & Apple Silicon), Linux (x86_64 & ARM64), and GitHub Codespaces
- **Declarative**: All configurations defined in version-controlled Nix files
- **Reproducible**: Same environment everywhere, every time
- **Secure**: Pre-commit hooks to prevent committing secrets
- **Comprehensive**: Includes shell (Zsh), editor (Neovim), multiplexer (Tmux), and many dev tools
- **Determinate Nix**: Uses Determinate Systems' Nix installer for better UX, flakes enabled by default, and easier uninstallation

## What's Included

### Shell & Terminal
- **Zsh** with autosuggestions, syntax highlighting, and custom aliases
- **Tmux** with sensible defaults and vi-mode
- **Starship** prompt (optional)

### Development Tools
- **Git** with delta for better diffs
- **Just** - command runner
- **Neovim** with essential plugins
- **direnv** - environment switcher
- **Docker** & Docker Compose

### CLI Utilities
- **Modern Unix tools**: `bat` (cat), `eza` (ls), `fd` (find), `ripgrep` (grep)
- **Fuzzy finder**: `fzf`
- **Data tools**: `jq`, `yq`
- **GitHub CLI**: `gh`
- **lazygit** - terminal UI for git

### Language Support
- Node.js
- Python 3
- Rust (rustc + cargo)
- Go

### Security
- Pre-commit hooks
- Gitleaks (secret detection)
- Git-secrets
- Comprehensive .gitignore

## Quick Start

### GitHub Codespaces (Easiest!)

1. Open this repository in GitHub Codespaces
2. Wait for the devcontainer to build and setup script to run
3. Restart your terminal
4. You're ready to go!

### macOS

1. **Install Determinate Nix**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

   Note: Determinate Nix comes with flakes enabled by default, so no additional configuration needed!

2. **Clone and Apply**:
   ```bash
   git clone <your-repo-url> ~/nix-dotfiles
   cd ~/nix-dotfiles

   # For Intel Mac:
   nix run home-manager -- switch --flake .#user@darwin-x86

   # For Apple Silicon Mac:
   nix run home-manager -- switch --flake .#user@darwin-arm
   ```

3. **Set up pre-commit hooks**:
   ```bash
   pre-commit install
   ```

### Linux

1. **Install Determinate Nix**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

   Note: Determinate Nix comes with flakes enabled by default and installs in multi-user mode automatically!

2. **Clone and Apply**:
   ```bash
   git clone <your-repo-url> ~/nix-dotfiles
   cd ~/nix-dotfiles
   nix run home-manager -- switch --flake .#user@linux
   ```

3. **Set up pre-commit hooks**:
   ```bash
   pre-commit install
   ```

4. **Change default shell to Zsh** (optional):
   ```bash
   chsh -s $(which zsh)
   ```

## Initial Configuration

Before using, customize these settings in `home.nix`:

1. **Git configuration**:
   ```nix
   git = {
     userName = "Your Name";      # Change this!
     userEmail = "your@email.com"; # Change this!
   };
   ```

2. Review and adjust:
   - Shell aliases
   - Neovim configuration
   - Tmux keybindings

## Usage

### Applying Configuration Changes

After editing configuration files:

```bash
# Apply changes
home-manager switch --flake .#<your-config>

# Example for Linux:
home-manager switch --flake .#user@linux

# Example for macOS (Apple Silicon):
home-manager switch --flake .#user@darwin-arm
```

### Updating Packages

```bash
# Update flake inputs (nixpkgs, home-manager)
nix flake update

# Apply updates
home-manager switch --flake .#<your-config>
```

### Installing Claude Code

Claude Code is installed via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

This is automatically done in the GitHub Codespaces setup script.

## Common Tasks

### Adding a New Package

1. Edit `home.nix`
2. Add package to the `home.packages` list:
   ```nix
   home.packages = with pkgs; [
     # ... existing packages ...
     your-new-package
   ];
   ```
3. Apply: `home-manager switch --flake .#<config>`

### Finding Packages

Search for packages at: https://search.nixos.org/packages

Or use command line:
```bash
nix search nixpkgs <package-name>
```

### Configuring Programs

Most programs have dedicated `programs.<name>` sections in `home.nix`. Check the [Home Manager options](https://mipmip.github.io/home-manager-option-search/) for available settings.

### Rolling Back Changes

Home Manager keeps previous generations:

```bash
# List generations
home-manager generations

# Rollback to previous generation
/nix/store/<hash>-home-manager-generation/activate
```

## Project Structure

```
.
├── flake.nix                   # Nix flake configuration
├── home.nix                    # Home Manager configuration
├── .devcontainer/              # GitHub Codespaces setup
│   ├── devcontainer.json
│   └── setup.sh
├── .pre-commit-config.yaml     # Pre-commit hooks
├── .gitignore                  # Git ignore patterns
├── CLAUDE.md                   # Documentation for Claude AI
└── README.md                   # This file
```

## Security

This repository includes multiple layers of protection against accidentally committing secrets:

1. **Pre-commit hooks**: Automatically run on every commit
   - Gitleaks: Detects secrets in code
   - detect-secrets: Additional secret scanning
   - Checks for private keys, AWS credentials, etc.

2. **Comprehensive .gitignore**: Blocks common secret file patterns

3. **Git-secrets**: Prevents committing AWS credentials

### Setting up Pre-commit Hooks

```bash
# Install hooks (one-time)
pre-commit install

# Run manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

## Platform-Specific Notes

### macOS
- Docker requires Docker Desktop
- Some CLI tools may behave differently (BSD vs GNU)
- Rosetta 2 required for x86_64 packages on Apple Silicon

### Linux
- Native Docker support
- May require additional setup for GUI applications
- Shell needs to be changed manually to Zsh

### GitHub Codespaces
- Automatic setup via devcontainer
- Limited to Linux (x86_64)
- Docker-in-Docker enabled
- Pre-installed VS Code extensions for Nix

## Troubleshooting

### "Permission denied" errors
Make sure Nix is properly installed and your user is in the `nix-users` group.

### Changes not applying
Try rebuilding with verbose output:
```bash
home-manager switch --flake .#<config> --show-trace
```

### Package not found
Update your flake inputs:
```bash
nix flake update
```

### Pre-commit hooks failing
Run manually to see detailed errors:
```bash
pre-commit run --all-files --verbose
```

### Uninstalling Nix
If you need to uninstall Determinate Nix:
```bash
/nix/nix-installer uninstall
```

## Resources

- [Determinate Systems - Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options Search](https://mipmip.github.io/home-manager-option-search/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Zero to Nix](https://zero-to-nix.com/)

## Contributing

1. Make changes in a feature branch
2. Test on your platform
3. Ensure pre-commit hooks pass
4. Submit a pull request

## License

This is a personal dotfiles repository. Feel free to fork and adapt to your needs!

## Acknowledgments

Built with:
- [Nix](https://nixos.org/)
- [Home Manager](https://github.com/nix-community/home-manager)
- Various open-source tools and configurations from the community
