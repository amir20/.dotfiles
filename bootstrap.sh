#!/usr/bin/env bash

set -e

# Install brew if it doesn't already exist
command -v brew > /dev/null 2>&1  || (yes '' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)")

# Install all things brew related 
for p in ctop git grc httpie jq fzf fasd fish pv progress node pyenv rbenv yarn wget tree tmux the_silver_searcher stow ssh-copy-id; do    
    echo -n "Checking for $p..."
    brew ls | grep -q $p || (echo -n "installing..." && brew install $p)
    echo
done

echo "Checking if curl is installed and installing if not..."
brew ls | grep -q curl || brew install curl --with-nghttp2

echo "Doing brew upgrade..."
brew upgrade

# Cask install tools
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

for p in java pycharm-ce visual-studio-code keepingyouawake docker insomnia; do    
    echo -n "Checking for cask $p..."
    brew cask ls | grep -q $p || (echo -n "installing..." && brew cask install $p)
    echo
done

# Setup fish 
echo "Setting up fish..."
grep -q -F '/usr/local/bin/fish' /etc/shells || echo '/usr/local/bin/fish' >> /etc/shells
test $SHELL = "/usr/local/bin/fish" || chsh -s /usr/local/bin/fish

echo "Setting up fisher..."
# Install fisher 
fish -c 'fisher' || curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher

# Stow fisher
stow fisher

# Run fisher 
fish -c 'fisher'

# Change settings for fish plugins
fish -c 'set -U fish_operator " ⟩ "'
fish -c 'set -U VIRTUALFISH_PLUGINS "auto_activation"'

# Other stow files 
stow git pep ssh vim 

# Install vim-sensible
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
(cd ~/.vim/bundle && git clone https://github.com/tpope/vim-sensible.git)

