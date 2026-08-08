{ config, lib, ... }:
{
  imports = [ ./exedev.nix ];

  # The single-user Nix installation used on Sprites does not enable these
  # globally, unlike Determinate Nix on the other supported machines.
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = config.home.homeDirectory;
    history = {
      ignoreDups = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      save = 1000;
      share = true;
      size = 1000;
    };
    shellAliases = config.programs.bash.shellAliases;
    initContent = lib.mkOrder 1200 ''
      source ${../config/shell/common.sh}
      [[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
    '';
  };

  programs.fzf.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
}
