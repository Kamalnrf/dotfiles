# Terminal session persistence: cmux vs tmux-resurrect/continuum

_Checked 2026-08-26 against cmux `1498ac8`, tmux-resurrect `cff343c`, and tmux-continuum `0698e8f`. These projects, especially cmux, are changing quickly._

## Bottom line

- **Closing/reopening a terminal is not the same as rebooting.** A detached tmux **server and its child processes remain alive** when cmux (or another terminal client) closes; reconnecting with `tmux attach` returns to the same processes and in-memory terminal history. An OS restart kills those processes. tmux-resurrect then **reconstructs** selected state and relaunches selected commands; it does not revive process memory.
- **cmux itself snapshots app state, not arbitrary processes.** It recreates windows/workspaces/panes, CWDs and bounded best-effort scrollback after app or OS restart. Current cmux can additionally reconstruct supported agent sessions by recording their native IDs and launching their resume commands. For Claude Code that is a fresh `claude --resume <id>` process displaying the previous conversation—not survival of the old PID.
- Therefore, for a Claude session that must remain literally live across a **cmux quit/crash**, run it inside tmux and reattach. Across an **OS reboot**, no local solution preserves the process; use cmux's Claude integration to resume the persisted Claude conversation, or build an explicit tmux-resurrect strategy/hook that records and resumes the Claude session ID. Merely restarting `claude` is not equivalent.

## Findings from this machine

The poor tmux recovery has a concrete configuration cause in addition to resurrect's inherent limits:

- `@continuum-save-interval` is correctly set to five minutes, but the newest file in `~/.tmux/resurrect` was from **2026-08-09**, 17 days before this inspection.
- Continuum is loaded before Catppuccin and before the final `status-right` assignments. Continuum installs its autosave command by prepending it to `status-right`; the later assignments replace that option. The live `status-right` contains only the three Catppuccin modules, so **continuum autosave is not running**. This is the plugin's documented known issue.
- The latest snapshot does contain session names, layouts and pane CWDs, explaining why those sometimes return. Pane-content capture is not enabled. It records `amp` in pane metadata, but `@resurrect-processes` adds only `ssh`, so Amp/Claude processes are not restarted; even if they were, a plain restart would not resume the same agent conversation.
- There are two snapshot directories: active `~/.tmux/resurrect` and stale `~/.local/share/tmux/resurrect`. The `tattach` helper deliberately prefers the former when it exists, so this is confusing but not the current restore failure.
- Installed Nix packages are old snapshots (`tmux-resurrect` 2022-05-01 and `tmux-continuum` 2022-01-25). That is worth updating, but it does not explain the missing saves: the overwritten status hook does.

The cmux observation is also directly corroborated locally. cmux 0.64.20 has a versioned app-session snapshot, a Claude hook registry containing a captured session, and saved terminal history showing cmux issue `claude --resume <session-id>` in the original CWD. The old Claude process did not survive; cmux reconstructed the conversation using Claude's persisted session.

Implemented on 2026-08-26: status construction now happens with the Catppuccin configuration and continuum loads last, preserving its hidden `#(...)` autosave command. Visible-pane capture is enabled rather than full-history capture. A forced interval check advanced the continuum timestamp and produced a valid snapshot containing all five live panes, three windows and five pane-content captures. Pane capture only replays text and may store sensitive terminal output; it does not restore a live TUI or agent process.

## What is preserved/restored

| State | cmux relaunch / reboot | Live tmux server after terminal closes | tmux-resurrect after tmux/process termination |
|---|---|---|---|
| Session/window/pane metadata | Window, workspace and pane layout; workspace metadata is app-owned snapshot state | Exact live tmux sessions/windows/panes | Sessions/windows/panes/order, exact layouts (including zoom), focus/active/alternate state, grouped sessions |
| Pane CWD | Yes | Yes, because pane/process is still live | Yes, `#{pane_current_path}` is saved and new panes are created with `-c` |
| Pane content/history | Best effort, bounded text replay; current source caps capture at 4,000 lines and 400,000 characters per terminal. It can be incomplete or visually imperfect when TUIs redraw/clear/alternate-screen. | Actual tmux scrollback remains in memory | **Off by default.** `@resurrect-capture-pane-contents 'on'` captures tmux history (full by default, or visible area) and prints it into a newly created shell. This is text replay, not restored screen/TUI state. `default-command` containing `&&`/`||` is a documented problem. |
| Running command/process | Arbitrary commands are not checkpointed. Unsupported panes reopen as normal terminals. Trusted custom resume bindings can run an attach/restart command. | Same PID/process tree continues; attach is reconnection | Old PID/state is gone. A command discovered from `ps` is run again only if allowlisted/configured; process-private state, sockets, jobs and credentials are not checkpointed. |
| Claude Code | With integration enabled, cmux's wrapper/hooks persist the Claude session ID and pane/workspace association, then run `claude --resume <id>` in the rebuilt pane. | Same Claude process remains visible after reattach | No built-in Claude strategy and `claude` is not in the default process list. Adding it may relaunch a command, but reliable conversation recovery requires preserving the session ID and deliberately issuing `claude --resume <id>`. |

cmux writes versioned JSON at `~/Library/Application Support/cmux/session-<bundle-id>.json` plus a previous-launch cache. Agent hook records live under `~/.cmuxterm/<agent>-hook-sessions.json` and contain session ID, cmux workspace/surface IDs, CWD, PID when available, and a sanitized launch command. Restore builds topology first and then executes a one-shot native resume command. Snapshot autosave is every **8 seconds** in current source, with termination-time saving as well; a hard power loss can lose changes since the last completed snapshot.

tmux-resurrect saves manually with `prefix C-s` and restores with `prefix C-r`. Its default conservative restart list is `vi vim nvim emacs man less more tail top htop irssi weechat mutt`. `@resurrect-processes` supports exact entries, `~` substring matches, `->` replacement commands, and `*` saved arguments; `:all:` is explicitly dangerous because blindly rerunning a formerly safe command can be destructive. Vim/Neovim have an optional session-file strategy; mosh and irb have supplied strategies. Node launchers may hide original arguments from `ps`, another reason command reconstruction is not process restoration. Save/restore extension points are `@resurrect-hook-post-save-layout`, `@resurrect-hook-post-save-all`, `@resurrect-hook-pre-restore-all`, and `@resurrect-hook-pre-restore-pane-processes`.

tmux-continuum automates tmux-resurrect: default save interval **15 minutes**, first save 15 minutes after startup, configurable in minutes with `@continuum-save-interval`; `0` disables it. It injects work into `status-right`, so status must be on and a later theme/plugin must not overwrite it (put continuum last). `@continuum-restore 'on'` restores only when the tmux **server starts**, not when `.tmux.conf` is sourced. With multiple servers, only the first gets autosave/autorestore. Backups older than 30 days are pruned while at least five are retained.

## Recommended macOS configuration

### Prefer cmux-native Claude recovery

1. Enable the Claude Code integration in cmux Settings; Claude is handled through the cmux wrapper (the generic `cmux hooks setup` command installs other detected integrations).
2. Keep **Settings → Terminal → Resume Agent Sessions on Reopen** enabled (equivalent setting: `"terminal": { "autoResumeAgentSessions": true }`). Verify capture before relying on it with `cmux sessions --agent claude --json`.
3. Treat this as **conversation reconstruction**. For arbitrary long-running servers, REPLs, SSH, vim, or shells, either run them in tmux or set a reviewed custom binding such as `cmux surface resume set --kind tmux --checkpoint work --shell "tmux attach -t work"`. cmux only autoruns bindings it trusts/user-approves and strips sensitive environment keys.

### Add tmux durability

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum' # after themes/plugins that alter status-right
set -g @continuum-restore 'on'
set -g @continuum-save-interval '5'          # smaller loss window than default 15
# Optional textual history replay; assess privacy/storage and default-command caveat:
set -g @resurrect-capture-pane-contents 'on'
```

- For **cmux app restarts**, leave tmux running and reconnect/attach; do not depend on resurrect.
- Before a planned OS restart, press `prefix C-s`; continuum has no special shutdown save hook and its latest snapshot may be up to the configured interval old.
- Do **not** use `@resurrect-processes ':all:'`. Do not add plain `claude` expecting continuity. Prefer cmux's native ID-aware resume. If implementing a tmux-only solution, use resurrect's save/restore hooks (or a purpose-built strategy) to persist the exact Claude session ID and execute `claude --resume <id>` in the matching pane.
- `@continuum-boot 'on'` on macOS installs `~/Library/LaunchAgents/Tmux.Start.plist` and opens Terminal.app by default (options exist for iTerm, kitty, or Alacritty); it may require Accessibility permission. This is dated UI automation and does not list cmux as a launch target, so normally let cmux launch at login and attach, rather than enabling continuum boot.

## Platform and reliability constraints

- cmux is a native **macOS** app. Its scrollback promise is explicitly best effort; snapshot limits and non-graceful-exit timing matter. Manual fallback is **History → Restore Previous App Launch**, `⌘⇧O`, or `cmux restore-session`.
- tmux-resurrect requires tmux ≥1.9 and Bash and reports Linux, macOS/OS X, and Cygwin support. Its process capture uses `ps`, so platform/process wrappers affect the command observed.
- tmux-continuum has the same stated tested platforms and dependencies, but autosave depends on tmux status-line evaluation. macOS boot uses launchd plus terminal GUI scripting; Accessibility denial prevents first boot launch. Automatic restore is server-start-only, and current open issues report save/restore/boot edge cases, so periodically inspect `~/.tmux/resurrect/last` and test recovery rather than assuming it works.

## Primary sources

### cmux
- Official session-restore contract and commands: <https://cmux.com/docs/session-restore>
- Agent integrations, stored metadata, hibernation/resume semantics and troubleshooting: <https://github.com/manaflow-ai/cmux/blob/1498ac8bc20bb5ba59c4a1d5ce2ef44af1f94645/docs/agent-hooks.md>
- Snapshot cadence and scrollback limits: <https://github.com/manaflow-ai/cmux/blob/1498ac8bc20bb5ba59c4a1d5ce2ef44af1f94645/Sources/SessionPersistence.swift#L18-L35>
- Official repository/FAQ (macOS scope and restart claim): <https://github.com/manaflow-ai/cmux>

### tmux-resurrect
- Exact metadata, defaults, requirements and keys: <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/README.md>
- Program allowlist/rewrite syntax, warnings and Node/mosh constraints: <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/docs/restoring_programs.md>
- Pane-content behavior/caveat: <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/docs/restoring_pane_contents.md>
- Save/restore hooks: <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/docs/hooks.md>
- Saved pane fields and `ps` command capture: <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/scripts/save.sh> and <https://github.com/tmux-plugins/tmux-resurrect/blob/cff343cf9e81983d3da0c8562b01616f12e8d548/save_command_strategies/ps.sh>

### tmux-continuum
- Cadence, status-line dependency, server-start restore and requirements: <https://github.com/tmux-plugins/tmux-continuum/blob/0698e8f4b17d6454c71bf5212895ec055c578da0/README.md>
- Interval, first-save delay, disable switch and retention: <https://github.com/tmux-plugins/tmux-continuum/blob/0698e8f4b17d6454c71bf5212895ec055c578da0/docs/faq.md>
- macOS/Linux boot behavior and Accessibility caveat: <https://github.com/tmux-plugins/tmux-continuum/blob/0698e8f4b17d6454c71bf5212895ec055c578da0/docs/automatic_start.md>
- Multiple-server precedence: <https://github.com/tmux-plugins/tmux-continuum/blob/0698e8f4b17d6454c71bf5212895ec055c578da0/docs/multiple_tmux_servers.md>
- Official issue tracker (current operational constraints): <https://github.com/tmux-plugins/tmux-continuum/issues>
