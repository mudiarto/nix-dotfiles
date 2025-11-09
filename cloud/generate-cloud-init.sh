#!/usr/bin/env bash
# Generate cloud-init.yaml from template using environment variables
#
# This script reads SSH keys and configuration from environment variables
# (typically set in .envrc.local) and generates cloud-init.yaml
#
# Usage:
#   ./cloud/generate-cloud-init.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/cloud-init.yaml.template"
OUTPUT_FILE="${SCRIPT_DIR}/cloud-init.yaml"

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check required environment variables
if [ -z "$CLOUD_VM_USERNAME" ]; then
    echo "⚠️  Warning: CLOUD_VM_USERNAME not set, using default 'developer'"
    CLOUD_VM_USERNAME="developer"
fi

if [ -z "$DOTFILES_REPO_URL" ]; then
    echo "❌ Error: DOTFILES_REPO_URL not set"
    echo "   Set it in .envrc.local:"
    echo "   export DOTFILES_REPO_URL=\"https://github.com/YOUR_USERNAME/nix-dotfiles.git\""
    exit 1
fi

# Read SSH public keys from environment variables or files
SSH_KEYS=""

# Option 1: SSH keys provided directly in environment variable (one per line or comma-separated)
if [ -n "$SSH_PUBLIC_KEYS" ]; then
    # Convert to YAML array format with proper indentation
    while IFS= read -r key; do
        [ -z "$key" ] && continue
        SSH_KEYS="${SSH_KEYS}      - ${key}"$'\n'
    done <<< "$(echo "$SSH_PUBLIC_KEYS" | tr ',' '\n')"
fi

# Option 2: Read from SSH_PUBLIC_KEY_PATH_1, SSH_PUBLIC_KEY_PATH_2, etc.
for i in {1..10}; do
    var_name="SSH_PUBLIC_KEY_PATH_${i}"
    key_path="${!var_name}"

    if [ -n "$key_path" ] && [ -f "$key_path" ]; then
        key_content=$(cat "$key_path")
        SSH_KEYS="${SSH_KEYS}      - ${key_content}"$'\n'
    fi
done

# Option 3: Default to reading ~/.ssh/*.pub files if nothing else provided
if [ -z "$SSH_KEYS" ]; then
    echo "⚠️  No SSH keys found in environment variables"
    echo "   Checking ~/.ssh/ for public keys..."

    for pub_key in ~/.ssh/*.pub; do
        if [ -f "$pub_key" ]; then
            echo "   Found: $pub_key"
            key_content=$(cat "$pub_key")
            SSH_KEYS="${SSH_KEYS}      - ${key_content}"$'\n'
        fi
    done
fi

if [ -z "$SSH_KEYS" ]; then
    echo "❌ Error: No SSH public keys found!"
    echo ""
    echo "Set SSH keys in .envrc.local using one of these methods:"
    echo ""
    echo "Method 1: Direct key content"
    echo "  export SSH_PUBLIC_KEYS=\"ssh-ed25519 AAAA... user@host\""
    echo ""
    echo "Method 2: Multiple keys (comma or newline separated)"
    echo "  export SSH_PUBLIC_KEYS=\"ssh-ed25519 AAAA... key1,ssh-ed25519 BBBB... key2\""
    echo ""
    echo "Method 3: Path to public key files"
    echo "  export SSH_PUBLIC_KEY_PATH_1=\"\$HOME/.ssh/id_ed25519.pub\""
    echo "  export SSH_PUBLIC_KEY_PATH_2=\"\$HOME/.ssh/id_rsa.pub\""
    exit 1
fi

# Remove trailing newline
SSH_KEYS="${SSH_KEYS%$'\n'}"

echo "🔧 Generating cloud-init.yaml from template..."
echo "   Username: $CLOUD_VM_USERNAME"
echo "   Repo URL: $DOTFILES_REPO_URL"
echo "   SSH Keys: $(echo "$SSH_KEYS" | grep -c '- ssh')"

# Generate the file by replacing placeholders
sed -e "s|__CLOUD_VM_USERNAME__|${CLOUD_VM_USERNAME}|g" \
    -e "s|__DOTFILES_REPO_URL__|${DOTFILES_REPO_URL}|g" \
    "$TEMPLATE_FILE" > "${OUTPUT_FILE}.tmp"

# Replace SSH keys placeholder (handle multiline)
awk -v keys="$SSH_KEYS" '
    /__SSH_PUBLIC_KEYS__/ {
        print keys
        next
    }
    { print }
' "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE"

# Clean up
rm "${OUTPUT_FILE}.tmp"

echo "✅ Generated: $OUTPUT_FILE"
echo ""
echo "You can now use this file with cloud providers:"
echo "  AWS EC2:        aws ec2 run-instances --user-data file://$OUTPUT_FILE ..."
echo "  GCP:            gcloud compute instances create ... --metadata-from-file=user-data=$OUTPUT_FILE"
echo "  Azure:          az vm create ... --custom-data $OUTPUT_FILE"
echo "  DigitalOcean:   Use as user data when creating droplet"
echo ""
echo "⚠️  Remember: cloud-init.yaml is gitignored and contains your SSH keys"
