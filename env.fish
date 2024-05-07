#!/usr/bin/env fish

set -Ux RIPGREP_CONFIG_PATH $HOME/.ripgreprc
set -Ux FNM_COREPACK_ENABLED true 
set -Ux COREPACK_ENABLE_DOWNLOAD_PROMPT 0

abbr -a -U -- - 'cd -'
abbr -a -U -- l ls