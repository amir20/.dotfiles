if status is-interactive
    # Commands to run in interactive sessions can go here
    abbr -a -- g git
    abbr -a -- - 'cd -'
    abbr -a -- l ls
    abbr -a -- c code .
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
