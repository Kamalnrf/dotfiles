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

On macOS, the Home Manager profile also installs an OpenCode LaunchAgent. It
starts `opencode2 serve --service` at login, waits for Tailscale, and binds the
shared server to the current Tailscale IPv4 address on port `49374`. Its
password is stored in OpenCode's private, mode-600 service configuration, not
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

OpenCode 2 is a beta distributed through platform-specific npm packages, so its
version and hashes are pinned separately in `home/common.nix`. To find the next
values:

```sh
VERSION="$(npm view @opencode-ai/cli@beta version)"
npm view "@opencode-ai/cli-darwin-arm64@$VERSION" dist.integrity
npm view "@opencode-ai/cli-linux-x64-baseline@$VERSION" dist.integrity
```

## Thanks to...

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Kent C. Dodds](https://github.com/kentcdodds/dotfiles)
