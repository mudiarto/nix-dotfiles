{ config, pkgs, lib, platform ? "linux", ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    username =
      let user = builtins.getEnv "USER";
      in if user != "" then user else "vscode";
    homeDirectory =
      let home = builtins.getEnv "HOME";
          user = builtins.getEnv "USER";
          finalUser = if user != "" then user else "vscode";
      in if home != "" then home
         else if pkgs.stdenv.isDarwin then "/Users/${finalUser}"
         else "/home/${finalUser}";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "24.05";

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SHELL = "${pkgs.zsh}/bin/zsh";
      # npm configuration for global packages
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    };

    # Add npm global bin to PATH
    sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin"
    ];

    # Packages to install
    packages = with pkgs; [
      # Core development tools
      just          # Command runner
      jq            # JSON processor
      yq            # YAML processor
      ripgrep       # Fast grep alternative
      fd            # Fast find alternative
      fzf           # Fuzzy finder
      bat           # Better cat
      eza           # Better ls
      delta         # Better git diff
      direnv        # Environment switcher

      # Cloud and container tools
      docker-compose
      kubectl

      # Development utilities
      gh            # GitHub CLI
      lazygit       # Terminal UI for git
      tree          # Directory tree viewer
      wget
      curl
      unzip
      gnused
      gawk

      # Security tools
      pre-commit    # Git pre-commit hooks
      gitleaks      # Secret detection
      git-secrets   # Prevent committing secrets

      # Language tools and package managers
      nodejs        # Node.js
      python3       # Python
      rustc         # Rust compiler
      cargo         # Rust package manager
      go            # Go language
      mise          # Polyglot runtime manager (asdf alternative)
      uv            # Fast Python package installer

      # Nix tools
      nixpkgs-fmt   # Nix formatter
      nil           # Nix language server
    ];
  };

  # Programs configuration
  programs = {
    # Zsh shell
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        # Better defaults
        ls = "eza --icons";
        ll = "eza -la --icons";
        lt = "eza --tree --icons";
        cat = "bat";

        # Git shortcuts
        g = "git";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gd = "git diff";
        gco = "git checkout";

        # Common commands
        ".." = "cd ..";
        "..." = "cd ../..";

        # Docker shortcuts
        d = "docker";
        dc = "docker-compose";

        # Just shortcuts
        j = "just";
      };

      initContent = ''
        # Enable vi mode
        bindkey -v

        # Better history search
        bindkey "^R" history-incremental-search-backward

        # fzf integration
        if [ -n "''${commands[fzf-share]}" ]; then
          source "$(fzf-share)/key-bindings.zsh"
          source "$(fzf-share)/completion.zsh"
        fi

        # direnv hook
        if [ -n "''${commands[direnv]}" ]; then
          eval "$(direnv hook zsh)"
        fi

        # Custom prompt (simple)
        PROMPT='%F{blue}%~%f %F{green}❯%f '
      '';

      history = {
        size = 10000;
        path = "${config.home.homeDirectory}/.zsh_history";
        ignoreDups = true;
        share = true;
      };
    };

    # Git configuration
    git = {
      enable = true;

      settings = {
        user = {
          name = "Kusno Mudiarto";  # TODO: Customize this
          email = "kusno@mudiarto.com";  # TODO: Customize this
        };

        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };

        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "nvim";
        diff.tool = "nvimdiff";
        merge.tool = "nvimdiff";
        push.autoSetupRemote = true;
      };

      # Global gitignore
      ignores = [
        # OS files
        ".DS_Store"
        "Thumbs.db"
        "desktop.ini"

        # Editor files
        ".vscode/"
        ".idea/"
        "*.swp"
        "*.swo"
        "*~"

        # Temporary files
        "*.tmp"
        "*.log"
        ".env.local"

        # Common build artifacts
        "node_modules/"
        ".cache/"
        "dist/"
        "build/"
      ];
    };

    # Delta (better git diffs)
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "Nord";
      };
    };

    # Neovim
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        # Essential plugins
        vim-sensible
        vim-surround
        vim-commentary
        vim-fugitive

        # File navigation
        fzf-vim
        nerdtree

        # Appearance
        vim-airline
        nord-vim
      ];

      extraConfig = ''
        " Basic settings
        set number
        set relativenumber
        set expandtab
        set tabstop=2
        set shiftwidth=2
        set smartindent
        set ignorecase
        set smartcase
        set incsearch
        set hlsearch
        set clipboard=unnamedplus

        " Theme
        colorscheme nord

        " Key mappings
        let mapleader = " "
        nnoremap <leader>w :w<CR>
        nnoremap <leader>q :q<CR>
        nnoremap <leader>e :NERDTreeToggle<CR>
        nnoremap <leader>f :Files<CR>
        nnoremap <leader>g :Rg<CR>

        " Clear search highlighting
        nnoremap <leader>h :nohlsearch<CR>
      '';
    };

    # Tmux
    tmux = {
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      shortcut = "a";  # Ctrl-a prefix
      baseIndex = 1;
      escapeTime = 0;

      extraConfig = ''
        # Enable mouse mode
        set -g mouse on

        # Split panes using | and -
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %

        # Switch panes using Alt-arrow without prefix
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

        # Status bar
        set -g status-style bg=black,fg=white
        set -g status-left '[#S] '
        set -g status-right '%Y-%m-%d %H:%M'

        # Window status
        setw -g window-status-current-style fg=black,bg=white
      '';
    };

    # Direnv - automatic environment switching
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # fzf - fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # Starship prompt (optional, commented out as we have simple prompt)
    # starship = {
    #   enable = true;
    #   settings = {
    #     add_newline = false;
    #     character = {
    #       success_symbol = "[➜](bold green)";
    #       error_symbol = "[➜](bold red)";
    #     };
    #   };
    # };

    # bat - better cat
    bat = {
      enable = true;
      config = {
        theme = "Nord";
        pager = "less -FR";
      };
    };

    # eza - better ls
    eza = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Platform-specific configurations and custom dotfiles
  home.file = lib.mkMerge [
    # Common files for all platforms
    {
      ".config/justfile-templates/.keep".text = "";

      # Example: Link external file from dotfiles/ directory
      # Uncomment to use:
      # ".custom_aliases".source = ./dotfiles/custom_aliases.sh;

      # Example: Create file with recursive directory
      # ".config/myapp/config.json".text = ''
      #   { "setting": "value" }
      # '';

      # EditorConfig - define coding styles
      ".editorconfig".text = ''
        root = true

        [*]
        charset = utf-8
        end_of_line = lf
        insert_final_newline = true
        trim_trailing_whitespace = true

        [*.{js,jsx,ts,tsx,json,css,scss,yml,yaml}]
        indent_style = space
        indent_size = 2

        [*.{py,rs,go}]
        indent_style = space
        indent_size = 4

        [*.md]
        trim_trailing_whitespace = false

        [Makefile]
        indent_style = tab
      '';

      # Curl configuration
      ".curlrc".text = ''
        # Follow redirects
        --location

        # Show error messages
        --show-error

        # Resume downloads
        --continue-at -

        # Use compression
        --compressed
      '';

      # npm configuration - use user-local directory for global packages
      # This prevents permission issues with Nix's read-only store
      ".npmrc".text = ''
        prefix=''${HOME}/.npm-global
      '';

      # Wget configuration
      ".wgetrc".text = ''
        # Use timestamping
        timestamping = on

        # Follow FTP links
        follow_ftp = on

        # Retry a few times
        tries = 3

        # Wait between requests
        wait = 2
      '';
    }

    # Linux/Codespaces specific
    (lib.mkIf (platform == "linux") {
      ".config/platform".text = "linux";
    })

    # macOS specific
    (lib.mkIf (platform == "darwin") {
      ".config/platform".text = "darwin";
    })
  ];
}
