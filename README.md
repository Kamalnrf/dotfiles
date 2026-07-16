# dotfiles

## Installation

```sh
git clone https://github.com/Kamalnrf/dotfiles.git ~/dotfiles \
  && ~/dotfiles/setup
```

The setup script supports:

- Apple Silicon macOS as `kamal` in `/Users/kamal`
- x86_64 exe.dev VMs as `exedev` in `/home/exedev`

It installs Determinate Nix when needed, then activates the matching Home
Manager profile. It is safe to run again after pulling changes:

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

Machine-local shell settings belong in `~/.zshrc.local` on macOS or
`~/.bashrc.local` on exe.dev. Machine-local Git settings belong in
`~/.config/git/local`. Credentials and runtime state are intentionally not
managed by this repository.

## Updating pinned packages

```sh
cd ~/dotfiles
nix flake update
nix build --no-link .#homeConfigurations.kamal.activationPackage
git diff -- flake.lock
./setup
```

## Thanks to...

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Kent C. Dodds](https://github.com/kentcdodds/dotfiles)
