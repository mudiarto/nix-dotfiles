# Managing Secrets and Environment Variables

How to handle API keys, tokens, and other secrets in your Nix environment.

## Table of Contents

- [Using direnv (.envrc)](#using-direnv-envrc)
- [Best Practices](#best-practices)
- [Alternative Solutions](#alternative-solutions)
- [Common Patterns](#common-patterns)

---

## Using direnv (.envrc)

**direnv** is already configured in your `home.nix`! It automatically loads environment variables from `.envrc` files when you enter a directory.

### Quick Start

1. **Create `.envrc` in your project** (or home directory):

   ```bash
   cd ~/myproject
   cat > .envrc <<'EOF'
   # Load sensitive secrets (NOT committed to git)
   source_env_if_exists .envrc.local

   # Public environment variables (CAN be committed)
   export PROJECT_NAME="myproject"
   export NODE_ENV="development"
   EOF
   ```

2. **Create `.envrc.local` for secrets**:

   ```bash
   cat > .envrc.local <<'EOF'
   # THIS FILE IS IN .gitignore - safe for secrets

   # API Keys
   export OPENAI_API_KEY="sk-..."
   export ANTHROPIC_API_KEY="sk-ant-..."
   export GITHUB_TOKEN="ghp_..."

   # Database credentials
   export DATABASE_URL="postgresql://user:password@localhost/db"
   export REDIS_URL="redis://localhost:6379"

   # AWS credentials
   export AWS_ACCESS_KEY_ID="AKIA..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_DEFAULT_REGION="us-east-1"

   # Other secrets
   export STRIPE_SECRET_KEY="sk_test_..."
   export SLACK_WEBHOOK_URL="https://hooks.slack.com/..."
   EOF
   ```

3. **Allow direnv** (first time only):

   ```bash
   direnv allow .
   ```

4. **Use in your project**:

   ```bash
   # When you cd into the directory, variables are loaded automatically
   cd ~/myproject
   # direnv: loading .envrc
   # direnv: loading .envrc.local

   # Variables are now available
   echo $OPENAI_API_KEY
   ```

### Pattern: Separate Public and Secret Config

**`.envrc`** (committed to git):
```bash
#!/bin/bash

# Load secrets from local file
source_env_if_exists .envrc.local

# Public configuration
export APP_NAME="myapp"
export LOG_LEVEL="info"

# Development settings
export ENABLE_DEBUG="false"

# Remind user about secrets
if [ ! -f .envrc.local ]; then
  echo "⚠️  Warning: .envrc.local not found"
  echo "   Copy .envrc.local.example and add your secrets"
fi
```

**`.envrc.local`** (in .gitignore, contains secrets):
```bash
# Secrets - NEVER commit this file!
export API_KEY="secret_key_here"
export DATABASE_PASSWORD="secret_password"
```

**`.envrc.local.example`** (committed to git, template):
```bash
# Copy this file to .envrc.local and fill in your secrets
# cp .envrc.local.example .envrc.local

export API_KEY="your_api_key_here"
export DATABASE_PASSWORD="your_password_here"
```

### Global Secrets (Home Directory)

For secrets you want available everywhere:

```bash
# Create global .envrc in home directory
cat > ~/.envrc.local <<'EOF'
# Global secrets available in all projects

export GITHUB_TOKEN="ghp_..."
export NPM_TOKEN="npm_..."
export HOMEBREW_GITHUB_API_TOKEN="ghp_..."
EOF

# Load it from project .envrc files
# In any project's .envrc:
source_env_if_exists ~/.envrc.local
```

### Advanced direnv Patterns

#### Load Different Configs by Environment

```bash
# .envrc
#!/bin/bash

# Determine environment
ENVIRONMENT="${ENVIRONMENT:-development}"

# Load environment-specific config
source_env_if_exists ".envrc.${ENVIRONMENT}"

# Load local secrets
source_env_if_exists .envrc.local

echo "Loaded $ENVIRONMENT environment"
```

#### Use Nix Shell with direnv

```bash
# .envrc
#!/bin/bash

# Load Nix environment (if using nix-direnv)
use flake

# Then load secrets
source_env_if_exists .envrc.local
```

#### Conditional Loading

```bash
# .envrc
#!/bin/bash

# Load secrets only if file exists and is readable
if [ -f .envrc.local ] && [ -r .envrc.local ]; then
  source .envrc.local
else
  echo "⚠️  No .envrc.local found - using defaults"
  export API_KEY="development_key"
fi

# Platform-specific
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export PLATFORM="linux"
fi
```

---

## Best Practices

### ✅ DO

1. **Use `.envrc.local` pattern**:
   - `.envrc` → committed, public config
   - `.envrc.local` → gitignored, secrets
   - `.envrc.local.example` → template

2. **Add to `.gitignore`**:
   ```gitignore
   .envrc.local
   .envrc.secret
   .env.local
   .env
   ```

3. **Use descriptive variable names**:
   ```bash
   export OPENAI_API_KEY="sk-..."      # Good
   export KEY="sk-..."                  # Bad
   ```

4. **Document required variables**:
   ```bash
   # .envrc.local.example
   # OpenAI API key from https://platform.openai.com/api-keys
   export OPENAI_API_KEY="sk-..."

   # Database URL format: postgresql://user:pass@host:port/db
   export DATABASE_URL="postgresql://..."
   ```

5. **Validate critical variables**:
   ```bash
   # .envrc
   if [ -z "$API_KEY" ]; then
     echo "❌ Error: API_KEY not set in .envrc.local"
     return 1
   fi
   ```

### ❌ DON'T

1. **Never commit real secrets** to `.envrc` or any tracked file
2. **Don't use `export` in shell config** for secrets (use `.envrc` instead)
3. **Don't hardcode secrets** in scripts
4. **Don't share `.envrc.local`** - each team member has their own

---

## Alternative Solutions

### 1. Nix Secrets with sops-nix (Advanced)

For encrypted secrets in your Nix configuration:

```nix
# Add to flake.nix
inputs.sops-nix.url = "github:Mic92/sops-nix";

# Use in home.nix
imports = [ inputs.sops-nix.homeManagerModules.sops ];

sops = {
  age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  secrets = {
    "github_token" = {
      sopsFile = ./secrets.yaml;
    };
  };
};
```

**Pros**: Version controlled (encrypted), auditable
**Cons**: More complex setup, requires age/sops

### 2. 1Password CLI

Use 1Password for secret management:

```bash
# Install 1Password CLI (add to home.nix)
home.packages = [ pkgs._1password ];

# Use in .envrc
export OPENAI_API_KEY=$(op read "op://Personal/OpenAI/credential")
export GITHUB_TOKEN=$(op read "op://Personal/GitHub/token")
```

**Pros**: Centralized, secure, team sharing
**Cons**: Requires 1Password subscription

### 3. Pass (Unix Password Manager)

```bash
# Install pass (add to home.nix)
home.packages = [ pkgs.pass ];

# Use in .envrc
export API_KEY=$(pass show api/openai)
export DB_PASSWORD=$(pass show database/prod)
```

**Pros**: GPG-encrypted, git-friendly
**Cons**: Requires GPG setup

### 4. Environment-specific Files

```bash
# Different files for different environments
.env.development
.env.staging
.env.production

# Load in .envrc
ENV="${ENV:-development}"
source_env_if_exists ".env.${ENV}"
```

### 5. Secret Management Services

For production:
- **AWS Secrets Manager** - for AWS deployments
- **HashiCorp Vault** - enterprise secret management
- **Google Secret Manager** - for GCP
- **Azure Key Vault** - for Azure

---

## Common Patterns

### Pattern 1: Multi-Project Secrets

```bash
# ~/.envrc.local (global secrets)
export GITHUB_TOKEN="ghp_..."
export NPM_TOKEN="npm_..."

# ~/project-a/.envrc
source_env_if_exists ~/.envrc.local
export PROJECT="project-a"
export API_URL="https://api.project-a.com"

# ~/project-b/.envrc
source_env_if_exists ~/.envrc.local
export PROJECT="project-b"
export API_URL="https://api.project-b.com"
```

### Pattern 2: Team-Shared Config Template

**`.envrc`** (committed):
```bash
#!/bin/bash

# Load team config
source_env_if_exists .envrc.team

# Load personal secrets
source_env_if_exists .envrc.local

# Defaults if not set
export APP_PORT="${APP_PORT:-3000}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
```

**`.envrc.team`** (committed, team config):
```bash
# Team-wide configuration (no secrets!)
export APP_NAME="our-awesome-app"
export API_BASE_URL="https://api.staging.example.com"
export FEATURE_FLAGS="new_ui,dark_mode"
```

**`.envrc.local`** (gitignored, personal secrets):
```bash
# Your personal API keys and secrets
export DATABASE_URL="postgresql://localhost/mydb"
export AWS_PROFILE="myprofile"
```

### Pattern 3: Required vs Optional Secrets

```bash
# .envrc
#!/bin/bash

# Required secrets
required_vars=(
  "DATABASE_URL"
  "API_KEY"
)

# Check required variables
source_env_if_exists .envrc.local

missing=()
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    missing+=("$var")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "❌ Missing required environment variables:"
  printf '   - %s\n' "${missing[@]}"
  echo ""
  echo "Create .envrc.local with:"
  for var in "${missing[@]}"; do
    echo "export $var=\"your_value\""
  done
  return 1
fi

# Optional with defaults
export LOG_LEVEL="${LOG_LEVEL:-info}"
export DEBUG="${DEBUG:-false}"
```

### Pattern 4: Per-Tool Configuration

```bash
# .envrc.local

# AWS Configuration
export AWS_PROFILE="myprofile"
export AWS_REGION="us-east-1"

# Node.js / npm
export NPM_TOKEN="npm_..."
export NODE_ENV="development"

# Python / pip
export PIP_INDEX_URL="https://pypi.org/simple"

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Git
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="you@example.com"
```

---

## Example: Complete Setup

Let's set up a project with proper secret management:

### 1. Project Structure

```
myproject/
├── .envrc                    # Committed - public config
├── .envrc.local              # Gitignored - your secrets
├── .envrc.local.example      # Committed - template
└── .gitignore                # Include .envrc.local
```

### 2. Files

**`.gitignore`**:
```gitignore
.envrc.local
.envrc.secret
.env.local
```

**`.envrc`**:
```bash
#!/bin/bash

# Project configuration (safe to commit)
export PROJECT_NAME="myproject"
export APP_ENV="${APP_ENV:-development}"

# Load secrets from local file
source_env_if_exists .envrc.local

# Validate critical secrets exist
if [ -z "$API_KEY" ]; then
  echo "⚠️  Warning: API_KEY not set"
  echo "   Copy .envrc.local.example to .envrc.local"
fi

# Use nix-direnv if flake.nix exists
if [ -f flake.nix ]; then
  use flake
fi

echo "✓ Environment loaded: $APP_ENV"
```

**`.envrc.local.example`**:
```bash
# Copy this to .envrc.local and fill in your secrets
# cp .envrc.local.example .envrc.local

# API Keys
export API_KEY="your_api_key_here"
export OPENAI_API_KEY="sk-..."

# Database
export DATABASE_URL="postgresql://user:password@localhost:5432/dbname"

# AWS (if needed)
# export AWS_ACCESS_KEY_ID="AKIA..."
# export AWS_SECRET_ACCESS_KEY="..."
```

**`.envrc.local`** (you create this, not committed):
```bash
# Your actual secrets
export API_KEY="sk-real-secret-key"
export OPENAI_API_KEY="sk-ant-real-key"
export DATABASE_URL="postgresql://user:realpass@localhost:5432/mydb"
```

### 3. First-time Setup

```bash
cd myproject

# Copy template
cp .envrc.local.example .envrc.local

# Edit with your secrets
$EDITOR .envrc.local

# Allow direnv
direnv allow .

# Variables are now loaded!
echo $API_KEY
```

### 4. Team Onboarding

New team member just needs to:
1. Clone the repo
2. Copy `.envrc.local.example` to `.envrc.local`
3. Fill in their own credentials
4. Run `direnv allow .`

---

## Security Checklist

- [ ] `.envrc.local` is in `.gitignore`
- [ ] Never commit real secrets to git
- [ ] Use `.envrc.local.example` as template
- [ ] Run `direnv allow` after creating `.envrc`
- [ ] Validate required secrets exist
- [ ] Use different secrets for dev/staging/prod
- [ ] Rotate secrets regularly
- [ ] Use secret management service for production
- [ ] Never log or print secrets
- [ ] Don't share secrets in chat/email

---

## Quick Reference

```bash
# Allow direnv in current directory
direnv allow .

# Reload .envrc manually
direnv reload

# Check what direnv loaded
direnv exec . env | grep -i api

# Test without direnv
env -i bash --noprofile --norc

# Temporarily disable direnv
direnv deny .
```

---

## See Also

- [direnv documentation](https://direnv.net/)
- [sops-nix](https://github.com/Mic92/sops-nix) - Encrypted secrets in Nix
- [1Password CLI](https://developer.1password.com/docs/cli/)
- [pass](https://www.passwordstore.org/) - Unix password manager
- [Nix Guide](./nix.md) - General Nix operations
- [Managing Dotfiles](./managing-dotfiles.md) - Configuration file management
