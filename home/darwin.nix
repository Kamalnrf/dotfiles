{ config, lib, pkgs, ... }:
let
  opencodeServerPort = 49374;

  opencodeServer = pkgs.writeShellApplication {
    name = "opencode-server";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail

      readonly tailscale=/usr/local/bin/tailscale
      readonly opencode=${config.home.homeDirectory}/.local/bin/opencode2

      tailscale_ip=""
      for _ in $(seq 1 60); do
        tailscale_ip="$($tailscale ip -4 2>/dev/null | head -n 1 || true)"
        if [[ "$tailscale_ip" == 100.* ]]; then
          break
        fi
        tailscale_ip=""
        sleep 2
      done

      if [[ -z "$tailscale_ip" ]]; then
        printf '%s\n' "Tailscale did not provide an IPv4 address" >&2
        exit 1
      fi

      exec "$opencode" serve \
        --service \
        --hostname "$tailscale_ip" \
        --port ${toString opencodeServerPort} \
        --cors https://opencode.ai
    '';
  };

  ampRunner = pkgs.writeShellApplication {
    name = "amp-runner";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail

      readonly amp=${config.home.homeDirectory}/.local/bin/amp

      exec "$amp" --no-tui \
        --runner-id mac-studio \
        --discover-dirs=${config.home.homeDirectory}/workspace
    '';
  };
in
{
  launchd.agents.opencode-server = {
    enable = true;
    config = {
      ProgramArguments = [ "${opencodeServer}/bin/opencode-server" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      WorkingDirectory = config.home.homeDirectory;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/opencode-server.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/opencode-server.error.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = "${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin";
      };
    };
  };

  launchd.agents.amp-runner = {
    enable = true;
    config = {
      ProgramArguments = [ "${ampRunner}/bin/amp-runner" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      WorkingDirectory = "${config.home.homeDirectory}/workspace";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/amp-runner.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/amp-runner.error.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = "${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin";
      };
    };
  };

  home.packages = [
    pkgs.librespeed-cli
    pkgs.orbstack
  ];

  home.sessionPath = [
    "$HOME/.bin"
    "$HOME/.bun/bin"
    "$HOME/.deno/bin"
    "$HOME/.fly/bin"
    "$HOME/.juliaup/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.raindrop/bin"
    "$HOME/.codeium/windsurf/bin"
  ];

  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    source = ../config/ghostty/config;
    force = true;
  };

  xdg.configFile."rex/init.lua".source = ../config/rex/init.lua;

  targets.darwin.defaults."com.superlogical.rex" = {
    "Workspace.terminalFontName" = "Codelia Ligatures";
    "Workspace.terminalFontPointSize" = 16.0;
  };

  programs.git.settings = {
    core = {
      precomposeUnicode = false;
      trustCTime = false;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = config.home.homeDirectory;
    history = {
      append = true;
      extended = true;
      ignoreDups = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      save = 5000;
      share = true;
      size = 5000;
    };
    shellAliases = {
      python = "python3";
      pip = "pip3";
      vault = ''cd "/Users/kamal/Library/Mobile Documents/iCloud~md~obsidian/Documents/everything"'';
      rm = "trash";
      d = "cd ~/Documents/Dropbox";
      dl = "cd ~/Downloads";
      dt = "cd ~/Desktop";
      p = "cd ~/projects";
      g = "git";
      pg = "echo 'Pinging Google' && ping www.google.com";
      showFiles = "defaults write com.apple.finder AppleShowAllFiles YES; killall Finder";
      hideFiles = "defaults write com.apple.finder AppleShowAllFiles NO; killall Finder";
      deleteDSFiles = "find . -name '.DS_Store' -type f -delete";
      npm-update = "npx npm-check-updates --dep prod,dev --upgrade";
      yarn-update = "yarn upgrade-interactive --latest";
      max = "mosh 'vm+max-coder@exe.dev' bash -lc 'exec tmux new -A -s coding'";
      evrim = "mosh 'vm+evrim@exe.dev' bash -lc 'exec tmux new -A -s evrim'";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
    };
    initContent = lib.mkOrder 1200 ''
      source ${../config/shell/common.sh}
      source ${../config/shell/darwin.zsh}
      [[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
    '';
  };

  programs.fzf = {
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };
  programs.zoxide.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
}
