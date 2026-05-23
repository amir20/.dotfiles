#!/usr/bin/env bash

set -e

# Install brew if it doesn't already exist
command -v brew > /dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all things brew related (chezmoi included)
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew bundle

# Apply dotfiles from this repo via chezmoi. The repo root is used as the
# source, and `.chezmoiroot` points it at the `home/` subdirectory.
chezmoi init --source "$(cd "$(dirname "$0")" && pwd)" --apply
