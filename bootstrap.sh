#!/usr/bin/env bash

set -e
sudo -v

# Install brew
yes '' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install all things brew related 
brew install ctop git grc httpie jq fzf fasd fish pv progress node pyenv rbenv yarn wget tree tmux the_silver_searcher stow ssh-copy-id; true
brew install curl --with-nghttp2; true

# Cask install tools
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew cask install java pycharm-ce visual-studio-code docker

# Setup fish 
grep -q -F '/usr/local/bin/fish' /etc/shells || echo '/usr/local/bin/fish' >> /etc/shells
chsh -s /usr/local/bin/fish

# Install fisher 
curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher

# Stow fisher
stow fisher

# Run fisher 
fish -c 'fisher'

# Change operator
fish -c 'set -U fish_operator " ⟩ "'


# Installing vscode plugins 
code --install-extension EditorConfig.editorconfig
code --install-extension HookyQR.beautify
code --install-extension PeterJausovec.vscode-docker
code --install-extension christian-kohler.npm-intellisense
code --install-extension christian-kohler.path-intellisense
code --install-extension codezombiech.gitignore
code --install-extension donjayamanne.python
code --install-extension eg2.vscode-npm-script
code --install-extension flowtype.flow-for-vscode
code --install-extension k--kato.intellij-idea-keybindings
code --install-extension kamikillerto.vscode-colorize
code --install-extension lukehoban.go
code --install-extension magicstack.magicpython
code --install-extension octref.vetur
code --install-extension rebornix.ruby
code --install-extension ricard.postcss
code --install-extension robertohuertasm.vscode-icons
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension vmsynkov.colonize
code --install-extension waderyan.babelrc

# Other stow files 
stow git pep ssh vim 

# Install vim-sensible
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
(cd ~/.vim/bundle && git clone https://github.com/tpope/vim-sensible.git)

