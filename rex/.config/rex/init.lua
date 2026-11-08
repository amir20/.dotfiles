-- Rex config migrated from Ghostty, tmux and iTerm2.

-- Switch panes with shift+cmd+left/right
rex.bind("shift+cmd+left", "pane.focus.left")
rex.bind("shift+cmd+right", "pane.focus.right")

-- Open panes with opt+cmd+left/right
rex.bind("opt+cmd+left", "pane.split.left")
rex.bind("opt+cmd+right", "pane.split.right")

-- Switch tabs with shift+cmd+up/down
rex.bind("shift+cmd+up", "client.tab.previous")
rex.bind("shift+cmd+down", "client.tab.next")

-- Switch sessions with shift+opt+up/down
rex.bind("shift+opt+up", "session.previous")
rex.bind("shift+opt+down", "session.next")
