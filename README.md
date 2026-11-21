# dotfiles

## Installation

```sh
git clone https://github.com/Kamalnrf/dotfiles.git ~/dotfiles \
  && ~/dotfiles/setup
```

The setup script supports:

- Apple Silicon macOS as `kamal` in `/Users/kamal`
- x86_64 exe.dev VMs as `exedev` in `/home/exedev`
- x86_64 Sprite VMs as `sprite` in `/home/sprite`

It installs Nix when needed, then activates the matching Home Manager profile.
It is safe to run again after pulling changes:

```sh
cd ~/dotfiles
git pull
./setup
```

The setup script links `~/.config/home-manager` to `~/dotfiles`, so subsequent
activations can also use Home Manager's default command:

```sh
home-manager switch
```

Machine-local shell settings belong in `~/.zshrc.local` on macOS and Sprite,
or `~/.bashrc.local` on exe.dev. Machine-local Git settings belong in
`~/.config/git/local`. Credentials and runtime state are intentionally not
managed by this repository.

On macOS, the Home Manager profile also installs OpenCode and Amp LaunchAgents. The
OpenCode agent starts `opencode2 serve --service` at login, waits for Tailscale,
and binds the shared server to the current Tailscale IPv4 address on port
`49374`. The Amp agent starts `amp --no-tui --discover-dirs=~/workspace` at
login, serving every Git checkout under `~/workspace`. Its runner ID comes from
`~/.config/amp/runner-id` when that file exists (the Mac Studio's says
`mac-studio`), otherwise from the lowercased `LocalHostName`, so each Mac
registers as its own runner. Both agents restart on failure, with logs in
`~/Library/Logs/opencode-server.log` and `~/Library/Logs/amp-runner.log`.
Its password is stored in OpenCode's private, mode-600 service configuration, not
in this repository or the Nix store. The `--service` mode is important: the
terminal UI and remote web clients must use the same server to receive live
session events.

Set or rotate the password with OpenCode's service command:

```sh
openssl rand -hex 32
opencode2 service set password '<paste-the-generated-value-here>'
```

The server uses `opencode` as its username by default.

## New Mac

This repository restores the shell, editor, terminal, and LaunchAgents. It does
not restore apps, credentials, or `~/workspace`. On the new Mac, as user
`kamal`:

1. Install Xcode Command Line Tools (`xcode-select --install`) and the apps
   below, then sign in to each. Homebrew is not used.
2. Copy `~/.ssh` (or create a key and add it to GitHub), then run
   `gh auth login`.
3. Clone and activate: `git clone git@github.com:Kamalnrf/dotfiles.git ~/dotfiles && ~/dotfiles/setup`.
4. Clone the repositories you need into `~/workspace`. Work with no remote or
   unpushed commits exists only on the Mac Studio; reach it over Tailscale.

Manual installs (they update themselves, so they stay out of Nix):

- Essentials: Amp (CLI and app), Tailscale Standalone, Rex, Raycast, Google
  Chrome, Xcode (App Store)
- Chat and AI: ChatGPT, Claude, Discord, Slack, Television (`tv`, via
  vite-plus)
- Editors and dev: Zed, Ghostty, cmux, Conductor, Obsidian
- Browsers and utilities: Dia, Helium, Firefox, Screen Studio, Suspicious
  Package, Logi Capture, Logi Tune
- CLIs with their own installers: Claude Code, Codex, bun, deno, juliaup
- Rust: Nix supplies `rustup`; run `rustup default stable` once. Binaries from
  `cargo install` (such as `tv-sync`) go to `~/.cargo/bin`, which is on `PATH`.

Migration Assistant copies everything instead, including apps, keychains, and
uncommitted work. Afterwards, delete the copied `~/.config/amp/runner-id` so the
new Mac does not register as `mac-studio` too.

## Always-on remote Mac

The Mac Studio stays reachable over Tailscale (`kamals-mac-studio`) for SSH,
Screen Sharing, OpenCode, and the Amp runner. Tailscale Standalone and the
LaunchAgents start only after a GUI login, so the Mac must log in by itself
after a power cut:

- `sudo pmset -a autorestart 1 sleep 0 womp 1` boots after power returns and
  never sleeps.
- FileVault prevents automatic login. With FileVault on, macOS 26 can only be
  unlocked over SSH from the same LAN, which Tailscale cannot reach before
  unlock. For unattended recovery, turn FileVault off and set Users & Groups >
  Automatically log in as `kamal`.
- Remote Login and Screen Sharing in System Settings > General > Sharing.
- Ethernet instead of Wi-Fi, and a UPS if possible.

## Updating pinned packages

```sh
cd ~/dotfiles
nix flake update
nix build --no-link .#homeConfigurations.kamal.activationPackage
git diff -- flake.lock
./setup
```

Home Manager supplies Node/npm and installs OpenCode 2.0.29 through npm on first
activation, under `~/.local`. Later activations leave an existing installation
alone, so OpenCode can manage its own updates without being downgraded:

```sh
opencode upgrade
# Or select a version:
opencode upgrade 2.0.29
```

`NPM_CONFIG_PREFIX` points npm global installs at `~/.local`, whose `bin`
directory takes precedence over the Nix profile. First activation needs network
access. This reproduces initial setup, not the version after subsequent upgrades.
Restart the OpenCode LaunchAgent after upgrading to update the running server.

Amp is installed separately: `~/.local/bin/amp` launches `~/.amp/bin/amp`.
The dotfiles manage its runner LaunchAgent, but do not install the Amp CLI.

## Thanks to...

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Kent C. Dodds](https://github.com/kentcdodds/dotfiles)
