-- Tmux-style prefix bindings. Rex tabs correspond to tmux windows.
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>n", "client.tab.next")
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>z", "pane.zoom")
rex.bind("ctrl+b>x", "pane.close")
rex.bind("ctrl+b>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+b>o", "pane.focus_next")
rex.bind("ctrl+b>,", "client.tab.rename")
-- Session picker approximates tmux-expose; no equivalent project picker for p.
rex.bind("ctrl+b>s", "session.switch")
rex.bind("ctrl+b>r", "client.config.reload")

-- Let terminal programs (including nested tmux) receive Ctrl+B.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- Dvorak-native navigation, matching config/tmux/tmux.conf.
rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+t", "pane.focus", { direction = "down" })
rex.bind("alt+n", "pane.focus", { direction = "up" })
rex.bind("alt+s", "pane.focus", { direction = "right" })
rex.bind("alt+shift+h", "pane.resize", { direction = "left", amount = 5 })
rex.bind("alt+shift+t", "pane.resize", { direction = "down", amount = 5 })
rex.bind("alt+shift+n", "pane.resize", { direction = "up", amount = 5 })
rex.bind("alt+shift+s", "pane.resize", { direction = "right", amount = 5 })
