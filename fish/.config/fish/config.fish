if status is-interactive
    # Commands to run in interactive sessions can go here
    abbr -a -- g git
    abbr -a -- - 'cd -'
    abbr -a -- l ls
    abbr -a -- c code .
    atuin init fish --disable-up-arrow | source
end

