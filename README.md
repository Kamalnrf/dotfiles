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
`49374`. The Amp agent starts `amp --no-tui --runner-id mac-studio
--discover-dirs=~/workspace` at login, serving every Git checkout under
`~/workspace` as runner `mac-studio`. Both agents restart on failure, with logs in
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
