if status is-interactive
    # Commands to run in interactive sessions can go here
    abbr -a -- g git
    abbr -a -- - 'cd -'
    abbr -a -- l ls
    abbr -a -- c code .
    abbr -a -- d docker
    abbr -a -- z zed .
    atuin init fish --disable-up-arrow | source
end


test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish


if test -f ~/.orbstack/shell/init.fish
    source ~/.orbstack/shell/init.fish 2>/dev/null || :
end
