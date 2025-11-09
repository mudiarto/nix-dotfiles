# Cloud VM Deployment

Deploy your Nix + Home Manager dotfiles to cloud VMs (AWS EC2, GCP Compute Engine, Azure VMs, DigitalOcean Droplets).

## Quick Start

### 1. Configure Your Credentials

Edit `.envrc.local` in the repository root and set:

```bash
# Required: Your dotfiles repository URL
export DOTFILES_REPO_URL="https://github.com/YOUR_USERNAME/nix-dotfiles.git"

# Optional: VM username (defaults to 'developer')
export CLOUD_VM_USERNAME="developer"

# SSH public keys - Choose one method:

# Method 1: Direct key content
export SSH_PUBLIC_KEYS="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host"

# Method 2: Multiple keys (comma or newline separated)
export SSH_PUBLIC_KEYS="ssh-ed25519 AAAA... key1,ssh-ed25519 BBBB... key2"

# Method 3: Paths to public key files
export SSH_PUBLIC_KEY_PATH_1="$HOME/.ssh/id_ed25519.pub"
export SSH_PUBLIC_KEY_PATH_2="$HOME/.ssh/id_rsa.pub"
```

### 2. Generate cloud-init.yaml

```bash
# Load environment variables
direnv allow

# Generate cloud-init.yaml from template
./cloud/generate-cloud-init.sh
```

This creates `cloud/cloud-init.yaml` with your SSH keys and configuration. This file is gitignored and not committed.

### 3. Deploy to Cloud Provider

#### AWS EC2

```bash
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.medium \
  --user-data file://cloud/cloud-init.yaml \
  --key-name your-key-pair
```

#### GCP Compute Engine

```bash
gcloud compute instances create my-devenv \
  --image-family=debian-11 \
  --machine-type=e2-medium \
  --metadata-from-file=user-data=cloud/cloud-init.yaml
```

#### Azure VM

```bash
az vm create \
  --name my-devenv \
  --image Debian11 \
  --size Standard_B2s \
  --custom-data cloud/cloud-init.yaml
```

#### DigitalOcean Droplet

Use the DigitalOcean web console or API to create a droplet and paste the contents of `cloud/cloud-init.yaml` as user data.

## What Gets Installed

The cloud-init script automatically:

1. ✅ Updates packages and installs prerequisites
2. ✅ Creates a user account with sudo access and your SSH keys
3. ✅ Installs Determinate Nix
4. ✅ Clones your dotfiles repository
5. ✅ Applies Home Manager configuration
6. ✅ Installs all configured packages and tools
7. ✅ Sets up pre-commit hooks
8. ✅ Installs Claude Code CLI

## Files in This Directory

- **cloud-init.yaml.template** - Template with placeholders (committed to git)
- **cloud-init.yaml** - Generated file with your actual keys (gitignored, **not committed**)
- **generate-cloud-init.sh** - Script to generate cloud-init.yaml from template
- **setup-vm.sh** - Manual setup script for existing VMs
- **README.md** - This file

## Manual Setup (Existing VMs)

If you already have a VM and want to set it up manually:

```bash
# SSH into your VM
ssh user@your-vm-ip

# Download and run the setup script
curl -sSfL https://raw.githubusercontent.com/YOUR_USERNAME/nix-dotfiles/main/cloud/setup-vm.sh | bash

# Or clone and run locally
git clone https://github.com/YOUR_USERNAME/nix-dotfiles.git ~/nix-dotfiles
cd ~/nix-dotfiles
./cloud/setup-vm.sh
```

## Security Notes

⚠️ **Important Security Practices:**

1. **Never commit cloud-init.yaml** - It contains your SSH keys. The file is gitignored.
2. **Regenerate after key changes** - Run `./cloud/generate-cloud-init.sh` whenever you update SSH keys
3. **Keep .envrc.local private** - This file contains sensitive configuration
4. **Use the template** - Always edit `cloud-init.yaml.template`, never the generated file

## Troubleshooting

### Script fails to find SSH keys

Make sure you've set SSH keys in `.envrc.local`:

```bash
export SSH_PUBLIC_KEYS="$(cat ~/.ssh/id_ed25519.pub)"
```

Or specify paths:

```bash
export SSH_PUBLIC_KEY_PATH_1="$HOME/.ssh/id_ed25519.pub"
```

### Cloud-init logs

Check cloud-init logs on the VM:

```bash
# View cloud-init output
sudo cat /var/log/cloud-init-output.log

# Check for errors
sudo cloud-init analyze show
```

### Nix installation fails

SSH into the VM and check:

```bash
# Check if Nix is installed
which nix

# Check cloud-init status
sudo cloud-init status

# Manually run Nix installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --no-confirm
```

## Customization

Edit `cloud-init.yaml.template` to customize:

- Packages to install
- User groups and permissions
- Additional setup commands
- Post-installation scripts

After editing the template, regenerate:

```bash
./cloud/generate-cloud-init.sh
```

## Recommended VM Sizes

- **AWS EC2**: t3.medium or larger (2 vCPU, 4GB RAM)
- **GCP**: e2-medium or larger (2 vCPU, 4GB RAM)
- **Azure**: Standard_B2s or larger (2 vCPU, 4GB RAM)
- **DigitalOcean**: $12/month droplet or larger (2GB RAM minimum)

Smaller instances may work but compilation can be slow.
