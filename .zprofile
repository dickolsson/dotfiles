eval "$(/opt/homebrew/bin/brew shellenv)"

# Rancher Desktop shims, after Homebrew so brew-managed binaries win
# (Rancher path management set to "manual")
export PATH="$PATH:$HOME/.rd/bin"

# User-local binaries, last so system and brew-managed binaries win
export PATH="$PATH:$HOME/.local/bin"
