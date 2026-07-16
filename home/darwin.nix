{ config, lib, pkgs, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.bin"
    "$HOME/.bun/bin"
    "$HOME/.deno/bin"
    "$HOME/.fly/bin"
    "$HOME/.juliaup/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.raindrop/bin"
    "$HOME/.codeium/windsurf/bin"
  ];

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
      max = "ssh -t max-coder.exe.xyz 'tmux new -A -s coding'";
      evrim = "ssh -t evrim.exe.xyz 'tmux new -A -s evrim'";
      l = "ls -lFG";
      ll = "ls -1a";
      la = "ls -lAFG";
      lsd = "ls -lFG | grep --color=never '^d'";
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
