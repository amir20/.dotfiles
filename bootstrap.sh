#!/usr/bin/env bash

set -e

# Install brew if it doesn't already exist
command -v brew > /dev/null 2>&1  || (yes '' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)")

# Install all things brew related
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew bundle

# Setup fish
echo "Setting up fish..."
grep -q -F '/usr/local/bin/fish' /etc/shells || echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
test $SHELL = "/usr/local/bin/fish" || chsh -s /usr/local/bin/fish

echo "Setting up fisher..."
# Install fisher
fish -c 'fisher' || fish -c 'curl -sL git.io/fisher | source && fisher install jorgebucaran/fisher'

# Stow fisher
stow fisher

# Run fisher
fish -c 'fisher'

# Other stow files
stow git starship pep ssh vim fish rg

# Install vim-sensible
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
git clone https://github.com/junegunn/fzf.vim.git ~/.vim/pack/packages/start/fzf.vim
(cd ~/.vim/bundle && git clone https://github.com/tpope/vim-sensible.git &&  git clone https://github.com/itchyny/lightline.vim)

