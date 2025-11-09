# Managing Dotfiles with Home Manager

Two approaches for adding configuration files to your home directory.

## Approach 1: Declarative in home.nix (Recommended)

Define file contents directly in `home.nix`. This is the Home Manager way - better for reproducibility.

### Advantages
✅ Version controlled in the same file
✅ More reproducible
✅ No external file dependencies
✅ Can use Nix expressions and variables
✅ Clear what's being managed

### Use Cases
- Git configuration (use `programs.git`)
- Shell aliases and functions (use `programs.zsh`)
- Simple config files
- Generated configurations

### Examples

#### Using Built-in Program Modules (Best)

For programs with Home Manager modules, use the declarative configuration:

```nix
# Git configuration with global gitignore
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "your@email.com";

  # Global gitignore
  ignores = [
    ".DS_Store"
    "node_modules/"
    "*.swp"
  ];

  aliases = {
    st = "status";
    co = "checkout";
  };
};

# Zsh with shell aliases
programs.zsh = {
  enable = true;
  shellAliases = {
    ll = "ls -la";
    g = "git";
  };
  initExtra = ''
    # Custom shell functions
    mkcd() { mkdir -p "$1" && cd "$1"; }
  '';
};
```

#### Using home.file for Custom Files

For files without Home Manager modules:

```nix
home.file = {
  # Simple text file
  ".editorconfig".text = ''
    root = true

    [*]
    charset = utf-8
    indent_style = space
    indent_size = 2
  '';

  # Configuration with Nix variables
  ".myconfig".text = ''
    HOME_DIR=${config.home.homeDirectory}
    USER=${config.home.username}
  '';

  # JSON configuration
  ".config/app/config.json".text = builtins.toJSON {
    theme = "dark";
    fontSize = 14;
  };

  # YAML configuration (requires pkgs.remarshal or similar)
  # ".config/app/config.yaml".text = ...
};
```

## Approach 2: External Files with Symlinks

Keep configuration files separate and symlink them from `home.nix`.

### Advantages
✅ Easier to edit large files
✅ Better syntax highlighting in editors
✅ Can test files independently
✅ Familiar if coming from traditional dotfiles

### Disadvantages
❌ Need to manage multiple files
❌ Harder to see full configuration
❌ Files not evaluated by Nix (no variables)
❌ Need to commit separate files

### Use Cases
- Large configuration files
- Complex multi-file configs
- Binary files (images, fonts)
- Files you edit frequently

### Directory Structure

```
nix-dotfiles/
├── dotfiles/
│   ├── custom_aliases.sh
│   ├── .tmux.conf.local
│   ├── .vimrc.local
│   └── config/
│       └── app/
│           └── settings.json
├── flake.nix
└── home.nix
```

### Examples

#### Symlink Single File

```nix
home.file = {
  # Symlink from dotfiles/ directory
  ".custom_aliases".source = ./dotfiles/custom_aliases.sh;

  # Symlink to different location
  ".config/nvim/lua/custom.lua".source = ./dotfiles/neovim/custom.lua;
};
```

#### Symlink Entire Directory

```nix
home.file = {
  # Link entire directory
  ".config/myapp".source = ./dotfiles/config/myapp;

  # Link directory recursively
  ".local/share/themes".source = ./dotfiles/themes;
};
```

#### Conditional Symlinking

```nix
home.file = lib.mkMerge [
  # Common files
  {
    ".editorconfig".source = ./dotfiles/.editorconfig;
  }

  # Linux-specific
  (lib.mkIf (platform == "linux") {
    ".config/linux-app".source = ./dotfiles/linux-app;
  })

  # macOS-specific
  (lib.mkIf (platform == "darwin") {
    ".config/mac-app".source = ./dotfiles/mac-app;
  })
];
```

## Comparison Table

| Feature | Declarative (Approach 1) | External Files (Approach 2) |
|---------|-------------------------|----------------------------|
| **Version Control** | In home.nix | Separate files |
| **Nix Variables** | ✅ Yes | ❌ No |
| **Syntax Highlighting** | Limited | ✅ Full |
| **Easy to Edit** | Good for small files | ✅ Better for large files |
| **Reproducibility** | ✅ Highest | Good |
| **File Discovery** | All in one place | ✅ Organized by type |
| **Testing** | Requires rebuild | Can test directly |

## Recommended Strategy

Use a **hybrid approach**:

1. **Use built-in modules** when available:
   ```nix
   programs.git = { ... };
   programs.zsh = { ... };
   programs.tmux = { ... };
   ```

2. **Use `home.file.text`** for simple configs:
   ```nix
   ".editorconfig".text = ''...'';
   ".curlrc".text = ''...'';
   ```

3. **Use `home.file.source`** for:
   - Large configuration files (>50 lines)
   - Multi-file configurations
   - Files you edit very frequently
   - Binary files

## Examples in This Repository

### Currently Using Declarative Approach

- **Git config**: `programs.git` with `ignores` for global gitignore
- **Zsh config**: `programs.zsh` with aliases
- **Neovim**: `programs.neovim` with plugins
- **EditorConfig**: `home.file.".editorconfig".text`
- **Curl/Wget**: `home.file` with inline text

### Example External File (Commented Out)

See `dotfiles/custom_aliases.sh` and the commented example in `home.nix`:

```nix
# ".custom_aliases".source = ./dotfiles/custom_aliases.sh;
```

Uncomment and customize as needed!

## Migration Guide

### From Traditional Dotfiles to Home Manager

If you have existing dotfiles:

1. **Quick migration** (external files):
   ```bash
   # Move your dotfiles
   mv ~/.zshrc dotfiles/.zshrc
   mv ~/.gitconfig dotfiles/.gitconfig

   # Add to home.nix
   home.file.".zshrc".source = ./dotfiles/.zshrc;
   home.file.".gitconfig".source = ./dotfiles/.gitconfig;
   ```

2. **Better migration** (declarative):
   ```nix
   # Convert to Home Manager modules
   programs.zsh = {
     enable = true;
     # ... copy your .zshrc content here ...
   };

   programs.git = {
     enable = true;
     # ... copy your .gitconfig content here ...
   };
   ```

### Converting External to Declarative

```nix
# Before (external file)
home.file.".curlrc".source = ./dotfiles/.curlrc;

# After (declarative)
home.file.".curlrc".text = ''
  --location
  --show-error
  --compressed
'';
```

## Advanced Patterns

### Template Files with Variables

```nix
home.file.".config/app/config".text = ''
  USER=${config.home.username}
  HOME=${config.home.homeDirectory}
  EDITOR=${config.home.sessionVariables.EDITOR}

  # Platform-specific
  ${lib.optionalString (platform == "linux") "USE_X11=true"}
  ${lib.optionalString (platform == "darwin") "USE_AQUA=true"}
'';
```

### Executable Scripts

```nix
home.file.".local/bin/my-script" = {
  text = ''
    #!/usr/bin/env bash
    echo "Hello from my script"
  '';
  executable = true;
};
```

### Conditional Content

```nix
home.file.".bashrc".text = ''
  # Common settings
  export EDITOR=nvim

  ${lib.optionalString (config.programs.direnv.enable) ''
    eval "$(direnv hook bash)"
  ''}
'';
```

## See Also

- [Home Manager Manual - Managing Files](https://nix-community.github.io/home-manager/index.xhtml#sec-usage-dotfiles)
- [Home Manager Options - home.file](https://nix-community.github.io/home-manager/options.xhtml#opt-home.file)
- [Nix Guide](./nix.md) - General Nix operations
