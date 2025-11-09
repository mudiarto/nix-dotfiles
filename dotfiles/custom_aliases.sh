# Example external dotfile
# This file can be symlinked from home.nix using home.file

# Add your custom aliases here
alias myproject='cd ~/projects/myproject'
alias dockerclean='docker system prune -af'

# Add custom functions
mkcd() {
  mkdir -p "$1" && cd "$1"
}
