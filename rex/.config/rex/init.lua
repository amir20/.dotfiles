-- Rex config migrated from Ghostty, tmux and iTerm2.

-- Ghostty: ~/.config/ghostty/config
rex.bind("shift+cmd+right", "client.tab.next")     -- line 9:  keybind = cmd+shift+right=next_tab
rex.bind("shift+cmd+left", "client.tab.previous")  -- line 10: keybind = cmd+shift+left=previous_tab

-- Switch tabs with shift+cmd+up/down
rex.bind("shift+cmd+up", "client.tab.previous")
rex.bind("shift+cmd+down", "client.tab.next")

-- Switch sessions with opt+cmd+up/down
rex.bind("opt+cmd+up", "session.previous")
rex.bind("opt+cmd+down", "session.next")
