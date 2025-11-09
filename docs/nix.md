# Nix Guide for Beginners

A practical guide to common Nix operations using Determinate Nix with flakes and Home Manager.

## Table of Contents

- [Understanding Nix Concepts](#understanding-nix-concepts)
- [Basic Operations](#basic-operations)
- [Managing Packages](#managing-packages)
- [Adding Dependencies and Sources](#adding-dependencies-and-sources)
- [Running Services](#running-services)
- [Custom Scripts and Packages](#custom-scripts-and-packages)
- [Troubleshooting](#troubleshooting)
- [Learning Resources](#learning-resources)

---

## Understanding Nix Concepts

### Key Terms

- **Nix**: The package manager and build system
- **Flakes**: Modern way to manage Nix projects with reproducible inputs/outputs
- **Home Manager**: Tool to manage user environment and dotfiles declaratively
- **Derivation**: A build recipe that describes how to build a package
- **Store**: `/nix/store` - where all packages are stored (immutable)
- **Profile**: A collection of packages you've installed
- **Generation**: A snapshot of your system state (allows rollbacks)

### Your Setup

This repository uses:
- **Determinate Nix**: Enhanced Nix installer with flakes enabled by default
- **Flakes**: Defined in `flake.nix`
- **Home Manager**: Configuration in `home.nix`
- **Multiple configs**: `user@linux`, `user@darwin-x86`, `user@darwin-arm`

---

## Basic Operations

### Updating Your System

#### Update All Packages

```bash
# Update flake inputs (nixpkgs, home-manager)
nix flake update

# Apply updates
home-manager switch --flake .#user@linux

# Or use the Justfile
just update
just apply-linux
```

#### Update Specific Input

```bash
# Update only nixpkgs
nix flake lock --update-input nixpkgs

# Update only home-manager
nix flake lock --update-input home-manager
```

#### Check What Will Change (Dry Run)

```bash
# See what would change without applying
just dry-run user@linux

# Or manually
home-manager build --flake .#user@linux --dry-run
```

### Rollback (Undo Changes)

Home Manager keeps previous generations, allowing you to rollback.

#### List Previous Generations

```bash
home-manager generations
```

Output example:
```
2024-01-15 10:30:45 : id 42 -> /nix/store/abc123-home-manager-generation
2024-01-14 09:15:22 : id 41 -> /nix/store/def456-home-manager-generation
```

#### Rollback to Previous Generation

```bash
# Rollback to the previous generation
home-manager generations | head -2 | tail -1 | awk '{print $NF}' | xargs -I {} {}/activate

# Or manually find the path and activate
/nix/store/def456-home-manager-generation/activate
```

#### Rollback Specific Nix Profile

```bash
# List profile generations
nix profile history

# Rollback to previous
nix profile rollback
```

### Upgrading Nix Itself

```bash
# Determinate Nix updates itself
# Check current version
nix --version

# Upgrade Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
```

---

## Managing Packages

### Finding Packages

#### Search Online

- **Nix Package Search**: https://search.nixos.org/packages
- Filter by channel, license, platforms

#### Search Command Line

```bash
# Search for a package
nix search nixpkgs python

# Search with more details
nix search nixpkgs --json python | jq

# Search within your flake
nix search . <package-name>
```

### Adding Packages

#### Method 1: Edit home.nix (Recommended)

1. **Open `home.nix`**:
   ```nix
   home.packages = with pkgs; [
     # Existing packages
     git
     neovim

     # Add your new package here
     ripgrep
     htop
     postgresql
   ];
   ```

2. **Apply the changes**:
   ```bash
   home-manager switch --flake .#user@linux
   ```

3. **Verify installation**:
   ```bash
   which ripgrep
   htop --version
   ```

#### Method 2: Temporary Install (Testing)

```bash
# Install temporarily (only in current shell)
nix shell nixpkgs#htop

# Run command without installing
nix run nixpkgs#cowsay "Hello Nix!"

# Run specific version
nix shell nixpkgs/nixos-23.11#python3
```

#### Method 3: Imperative Install (Not Recommended)

```bash
# Install to profile (avoid this with Home Manager)
nix profile install nixpkgs#ripgrep

# List profile packages
nix profile list

# Remove from profile
nix profile remove ripgrep
```

**Note**: Prefer editing `home.nix` for reproducibility!

### Removing Packages

1. **Remove from `home.nix`**:
   ```nix
   home.packages = with pkgs; [
     git
     neovim
     # Remove the package from this list
   ];
   ```

2. **Apply changes**:
   ```bash
   home-manager switch --flake .#user@linux
   ```

3. **Clean up old generations** (optional):
   ```bash
   # Remove old generations older than 30 days
   nix-collect-garbage --delete-older-than 30d

   # Or more aggressive
   nix-collect-garbage -d
   ```

### Package Versions

#### Use Specific Version

```nix
# In home.nix
home.packages = [
  # Use specific package from nixpkgs
  pkgs.python311  # Python 3.11
  pkgs.nodejs_20  # Node.js 20

  # Or from a different nixpkgs version
  (builtins.getFlake "nixpkgs/nixos-23.11").legacyPackages.${pkgs.system}.python310
];
```

#### Pin Specific Commit

Edit `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/abc123def456";  # Specific commit
  };
}
```

---

## Adding Dependencies and Sources

### Adding Flake Inputs

Flake inputs are external dependencies (other flakes, nixpkgs versions, etc.).

#### Add New Input to flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add a new input - example: neovim plugins
    neovim-nightly = {
      url = "github:neovim/neovim?dir=contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Or a specific flake
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, home-manager, neovim-nightly, nur, ... }: {
    # Your outputs configuration
    # Now you can use neovim-nightly and nur in your config
  };
}
```

#### Update Flake Lock

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input neovim-nightly

# See what inputs you have
nix flake metadata
```

### Using Overlays

Overlays modify or add packages to nixpkgs.

#### Create an Overlay in home.nix

```nix
{ config, pkgs, lib, ... }:

{
  # Define overlay
  nixpkgs.overlays = [
    # Overlay 1: Modify existing package
    (final: prev: {
      # Override nodejs to use version 20
      nodejs = prev.nodejs_20;
    })

    # Overlay 2: Add custom package
    (final: prev: {
      my-custom-tool = prev.writeShellScriptBin "my-tool" ''
        echo "Hello from custom tool!"
      '';
    })
  ];

  # Now use the packages
  home.packages = with pkgs; [
    nodejs  # Will use nodejs_20
    my-custom-tool
  ];
}
```

### Using NUR (Nix User Repository)

NUR contains community packages not in nixpkgs.

1. **Add NUR to flake.nix**:
   ```nix
   inputs.nur.url = "github:nix-community/NUR";
   ```

2. **Use in home.nix**:
   ```nix
   { config, pkgs, nur, ... }:

   {
     home.packages = [
       nur.repos.some-user.some-package
     ];
   }
   ```

---

## Running Services

### Understanding Services in Home Manager

Home Manager can manage user services (systemd user services on Linux, launchd on macOS).

### Common Services Examples

#### PostgreSQL Database

```nix
# In home.nix
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;

    # Data directory
    dataDir = "${config.home.homeDirectory}/.local/share/postgresql";

    # Port
    settings = {
      port = 5432;
    };
  };
}
```

**Manage PostgreSQL**:
```bash
# Service runs automatically via systemd (Linux) or launchd (macOS)

# Check status (Linux)
systemctl --user status postgresql

# Restart
systemctl --user restart postgresql

# View logs
journalctl --user -u postgresql -f

# Connect to database
psql -h localhost -U $USER
```

#### Redis

```nix
# In home.nix
{
  services.redis = {
    enable = true;

    # Port
    settings = {
      port = 6379;
    };
  };
}
```

**Manage Redis**:
```bash
# Check status
systemctl --user status redis

# Connect
redis-cli
```

#### MySQL/MariaDB

```nix
# In home.nix
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    # Data directory
    dataDir = "${config.home.homeDirectory}/.local/share/mysql";

    # Additional settings
    settings = {
      mysqld = {
        port = 3306;
        bind-address = "127.0.0.1";
      };
    };
  };
}
```

#### Custom Service

```nix
# In home.nix
{
  # Define a custom systemd service
  systemd.user.services.my-app = {
    Unit = {
      Description = "My Custom Application";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nodejs}/bin/node /path/to/app.js";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
```

**Manage Custom Service**:
```bash
systemctl --user status my-app
systemctl --user restart my-app
systemctl --user enable my-app  # Start on boot
```

### Docker Services

Since Docker typically requires root, run it system-wide:

```bash
# Install Docker system-wide
sudo apt install docker.io  # Debian/Ubuntu
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Then use docker-compose in your projects
```

Or use Home Manager with rootless Docker (advanced).

---

## Custom Scripts and Packages

### Simple Scripts

#### Method 1: Shell Script in home.nix

```nix
# In home.nix
{
  home.packages = [
    # Create a simple script package
    (pkgs.writeShellScriptBin "hello" ''
      echo "Hello, $USER!"
      echo "Current directory: $(pwd)"
    '')

    # Script with dependencies
    (pkgs.writeShellScriptBin "git-summary" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.git}/bin/git log --oneline --graph --all -n 20
      echo "---"
      ${pkgs.git}/bin/git status
    '')
  ];
}
```

Usage:
```bash
hello
git-summary
```

#### Method 2: External Script File

1. **Create script file** `scripts/my-tool.sh`:
   ```bash
   #!/usr/bin/env bash
   echo "Running my custom tool"
   # Your script logic here
   ```

2. **Add to home.nix**:
   ```nix
   {
     home.packages = [
       (pkgs.writeShellApplication {
         name = "my-tool";
         text = builtins.readFile ./scripts/my-tool.sh;
         runtimeInputs = [ pkgs.curl pkgs.jq ];  # Dependencies
       })
     ];
   }
   ```

### Custom Packages (Derivations)

#### Simple Package

Create `pkgs/my-package.nix`:
```nix
{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "your-username";
    repo = "your-repo";
    rev = "v1.0.0";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  buildInputs = [ pkgs.nodejs ];

  installPhase = ''
    mkdir -p $out/bin
    cp my-script.sh $out/bin/my-package
    chmod +x $out/bin/my-package
  '';

  meta = with pkgs.lib; {
    description = "My custom package";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
```

Use in `home.nix`:
```nix
{
  home.packages = [
    (pkgs.callPackage ./pkgs/my-package.nix {})
  ];
}
```

#### Python Package with Dependencies

```nix
# In home.nix
{
  home.packages = [
    (pkgs.python3.withPackages (ps: with ps; [
      requests
      numpy
      pandas
      # Your Python dependencies
    ]))
  ];
}
```

Create a Python script:
```nix
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "my-python-script";
      runtimeInputs = [
        (pkgs.python3.withPackages (ps: [ ps.requests ps.click ]))
      ];
      text = ''
        python ${./scripts/my-script.py} "$@"
      '';
    })
  ];
}
```

### Development Shells (per-project)

Create a `shell.nix` or `flake.nix` in your project:

**shell.nix**:
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_20
    postgresql
    redis
    python311
    python311Packages.pip
  ];

  shellHook = ''
    echo "Welcome to the development environment!"
    export DATABASE_URL="postgresql://localhost/mydb"
  '';
}
```

**Use it**:
```bash
# Enter the shell
nix-shell

# Or with flakes
nix develop
```

**Project flake.nix**:
```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = with pkgs; [
          nodejs_20
          postgresql
        ];
      };
  };
}
```

---

## Troubleshooting

### Common Issues

#### 1. "Flakes not enabled"

**Issue**: `error: experimental Nix feature 'flakes' is disabled`

**Solution**: With Determinate Nix, this shouldn't happen. But if it does:
```bash
# Add to ~/.config/nix/nix.conf
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### 2. "Hash mismatch"

**Issue**:
```
error: hash mismatch in fixed-output derivation
  specified: sha256-AAAA...
  got:       sha256-BBBB...
```

**Solution**:
1. Use the "got" hash in your configuration
2. Or use `lib.fakeSha256` to get the real hash:
   ```nix
   sha256 = pkgs.lib.fakeSha256;
   ```
3. Build it, get the real hash, replace

#### 3. "Too many open files"

**Issue**: Nix hits file descriptor limits

**Solution**:
```bash
# Increase limits (Linux)
ulimit -n 4096

# Or permanently in /etc/security/limits.conf
* soft nofile 4096
* hard nofile 8192
```

#### 4. "Disk space full"

**Issue**: `/nix/store` grows large

**Solution**:
```bash
# Clean up old generations
nix-collect-garbage -d

# Or keep last N generations
nix-collect-garbage --delete-older-than 30d

# Check disk usage
du -sh /nix/store

# Optimize store (hard link duplicates)
nix-store --optimize
```

#### 5. "Build fails with cryptic error"

**Solution**: Use `--show-trace` for details:
```bash
nix flake check --show-trace
home-manager switch --flake .#user@linux --show-trace
```

#### 6. "Package conflicts"

**Issue**: Multiple versions of the same package

**Solution**:
```nix
# Use nixpkgs.config to handle conflicts
nixpkgs.config.allowUnfree = true;
nixpkgs.config.permittedInsecurePackages = [
  "python-2.7.18"  # If you need old Python
];
```

### Debugging Tips

#### Check what depends on a package

```bash
nix why-depends ~/.nix-profile /nix/store/...-some-package
```

#### See build logs

```bash
# Build with verbose output
nix build --print-build-logs .#homeConfigurations."user@linux".activationPackage

# Or
nix log /nix/store/...-some-package
```

#### Evaluate Nix expressions

```bash
# Evaluate a Nix expression
nix eval .#homeConfigurations."user@linux".config.home.packages

# Pretty print
nix eval .#homeConfigurations."user@linux".config.home.packages --json | jq
```

#### Check flake structure

```bash
# Show flake outputs
nix flake show

# Get flake metadata
nix flake metadata

# Check for errors
nix flake check --show-trace
```

### Getting Help

```bash
# Command help
nix --help
nix flake --help
home-manager --help

# Man pages
man nix
man home-configuration.nix

# Check Nix version
nix --version
home-manager --version
```

---

## Learning Resources

### Official Documentation

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **Nix Pills** (tutorial series): https://nixos.org/guides/nix-pills/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **Home Manager Options**: https://mipmip.github.io/home-manager-option-search/
- **NixOS Package Search**: https://search.nixos.org/packages
- **Determinate Nix**: https://github.com/DeterminateSystems/nix-installer

### Interactive Tutorials

- **Zero to Nix**: https://zero-to-nix.com/ - Best starting point
- **Nix.dev**: https://nix.dev/ - Practical guides
- **NixOS Wiki**: https://nixos.wiki/

### Community

- **Discourse**: https://discourse.nixos.org/
- **Reddit**: r/NixOS
- **Discord**: NixOS Discord server
- **Matrix**: #nix:nixos.org

### Video Resources

- **Jon Ringer's YouTube**: Nix tutorials
- **Burke Libbey's Nix videos**: Advanced topics
- **Nixology**: Video series on Nix concepts

### Books

- **Nix in Action** (Manning) - Comprehensive guide
- **NixOS in Production** - Deployment guide

### Example Repositories

- **NixOS/nixpkgs**: Browse package definitions
  https://github.com/NixOS/nixpkgs

- **Nix Community Configs**: Real-world examples
  https://github.com/nix-community/home-manager/tree/master/modules

- **Awesome Nix**: Curated list of resources
  https://github.com/nix-community/awesome-nix

### Cheat Sheets

- **Nix Flakes Cheat Sheet**: https://www.tweag.io/blog/2021-10-05-nix-flakes-guide/
- **Nix Command Reference**: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix.html

---

## Quick Reference Card

### Daily Commands

```bash
# Update and switch
nix flake update && home-manager switch --flake .#user@linux

# Search for package
nix search nixpkgs <package>

# Temporary shell with package
nix shell nixpkgs#<package>

# Run command once
nix run nixpkgs#<package>

# Validate config
just validate

# Clean up
nix-collect-garbage -d

# List generations
home-manager generations
```

### File Locations

- **Nix config**: `~/.config/nix/nix.conf`
- **Nix store**: `/nix/store/`
- **User profile**: `~/.nix-profile`
- **Home Manager state**: `~/.local/state/nix/profiles/home-manager`

### Important Concepts

- **Declarative**: Describe what you want, not how to get it
- **Reproducible**: Same inputs = same outputs
- **Immutable**: Packages in `/nix/store` never change
- **Atomic**: Changes apply all-or-nothing
- **Rollbackable**: Previous generations always available

---

## Next Steps

1. **Customize your config**: Edit `home.nix` to add packages you use
2. **Explore packages**: Browse https://search.nixos.org/packages
3. **Add a service**: Try running PostgreSQL or Redis
4. **Create a script**: Make a custom script with `writeShellScriptBin`
5. **Learn flakes**: Read the Flakes guide at https://zero-to-nix.com/
6. **Join community**: Ask questions on Discourse or Discord

Happy Nix-ing! 🚀
