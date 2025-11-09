# Dockerfile for Nix + Home Manager environment
# This creates a containerized development environment with all tools configured

FROM debian:bookworm-slim

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Determinate Nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install linux \
    --init none \
    --no-confirm

# Source Nix environment
ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"
ENV NIX_PROFILES="/nix/var/nix/profiles/default /home/$USERNAME/.nix-profile"
ENV NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

# Copy the dotfiles configuration
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/nix-dotfiles
WORKDIR /home/$USERNAME/nix-dotfiles

# Install Home Manager and apply configuration
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    nix run home-manager -- init --switch && \
    home-manager switch --flake .#user@linux

# Set up pre-commit hooks
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    pre-commit install --install-hooks || true

# Install Claude Code via npm
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    npm install -g @anthropic-ai/claude-code || echo "Claude Code installation skipped"

# Set Zsh as default shell
ENV SHELL=/home/$USERNAME/.nix-profile/bin/zsh

# Start with Zsh
CMD ["/home/developer/.nix-profile/bin/zsh"]
