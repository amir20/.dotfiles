#!/usr/bin/env bash

set -e

FISH_PATH="/opt/homebrew/bin/fish"

# Install brew if it doesn't already exist
command -v brew > /dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all things brew related
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew bundle

# Setup fish
echo "Setting up fish..."
grep -q -F "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
test "$SHELL" = "$FISH_PATH" || chsh -s "$FISH_PATH"

echo "Setting up fisher..."
# Install fisher
fish -c 'fisher' || fish -c 'curl -sL git.io/fisher | source && fisher install jorgebucaran/fisher'

# Stow configs
stow fisher lsd git starship pep ssh vim fish rg tmux ghostty claude

# Run fisher
fish -c 'fisher' || fish -c 'curl -sL git.io/fisher | source && fisher update'

fish ./env.fish

# Install vim plugins via native packages
VIM_PACK=~/.vim/pack/packages/start
mkdir -p "$VIM_PACK"
for repo in tpope/vim-sensible itchyny/lightline.vim junegunn/fzf.vim; do
    name="${repo##*/}"
    test -d "$VIM_PACK/$name" || git clone "https://github.com/$repo.git" "$VIM_PACK/$name"
done
