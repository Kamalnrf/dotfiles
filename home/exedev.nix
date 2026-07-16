{ config, lib, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/bin"
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" ];
    historyFile = "${config.home.homeDirectory}/.bash_history";
    historyFileSize = 10000;
    historySize = 5000;
    shellAliases = {
      python = "python3";
      pip = "pip3";
      dl = "cd ~/Downloads";
      p = "cd ~/projects";
      g = "git";
      pg = "echo 'Pinging Google' && ping www.google.com";
      npm-update = "npx npm-check-updates --dep prod,dev --upgrade";
      l = "ls -lF --color=auto";
      ll = "ls -1a --color=auto";
      la = "ls -lAF --color=auto";
      lsd = "ls -lF --color=auto | grep --color=never '^d'";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
    };
    initExtra = ''
      source ${../config/shell/common.sh}
      [[ -r "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
    '';
  };

  programs.fzf.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.direnv.enableBashIntegration = true;
}
