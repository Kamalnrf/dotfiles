{ config, lib, pkgs, ... }:
let
  tmuxExposeSrc = pkgs.fetchFromGitHub {
    owner = "cesarferreira";
    repo = "tmux.expose";
    rev = "4741e630226f5feee7f6ce94abc9c5d860b21a89";
    hash = "sha256-RYyTEpsEAUfD7DcP5QJgvHkwUPFyJJH4JB6ZX5l5ZDQ=";
  };

  tmuxExpose = pkgs.rustPlatform.buildRustPackage {
    pname = "tmux-expose";
    version = "unstable-2026-07-16";
    src = tmuxExposeSrc;
    cargoHash = "sha256-D0Cw30/bfjUZR5A7sxkhWhLzjyQ8Yk/tEO9ogu/Jzeo=";
  };

  tmuxExposePlugin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-expose";
    version = "unstable-2026-07-16";
    rtpFilePath = "tmux.expose.tmux";
    src = tmuxExposeSrc;
  };
in
{
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;

  home.sessionPath = [ "$HOME/.nix-profile/bin" ];

  home.packages = with pkgs; [
    bc
    btop
    delta
    fd
    flyctl
    hunk
    jq
    lsof
    mosh
    openssl
    ripgrep
    tmuxExpose
    tree
    uv
  ];

  home.file = {
    ".hushlogin".text = "";
    ".local/bin/tmux-project-popup" = {
      source = ../bin/tmux-project-popup;
      executable = true;
    };
  };

  home.sessionVariables = {
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    TMUX_RESURRECT_RESTORE = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh";
  };

  xdg.enable = true;
  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/nvim";
    "ripgrep/config".source = ../config/ripgrep/config;
  };

  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
      "Desktop.ini"
      "npm-debug.log"
      "yarn-error.log"
      ".history"
      "*.ignored/"
      "*.ignored.*"
      ".eslintcache"
      ".Spotlight-V100"
      ".Trashes"
      "._*"
      "Thumbs.db"
      "**/.claude/settings.local.json"
    ];
    includes = [ { path = "~/.config/git/local"; } ];
    settings = {
      user = {
        name = "Kamal Mukkamala";
        email = "kamalnrf@gmail.com";
      };
      apply.whitespace = "fix";
      branch.autoSetupRebase = "always";
      color.ui = true;
      core = {
        pager = "hunk pager";
        whitespace = "space-before-tab,-indent-with-non-tab,trailing-space";
        untrackedCache = true;
      };
      delta = {
        features = "night-owlish";
        side-by-side = true;
      };
      help.autocorrect = 1;
      init.defaultBranch = "main";
      interactive.diffFilter = "delta --color-only";
      merge.log = true;
      pull.rebase = true;
      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };
      alias = {
        s = "status -sb";
        rh = "reset --hard HEAD";
        b = "checkout -b";
        co = "checkout";
        ca = "commit -a --verbose";
        cp = "cherry-pick";
        amend = "commit -a --amend --no-edit";
        unstage = "restore --staged";
        cdiff = "!git diff $1 $1^";
        tags = "tag -l";
        branches = "branch --all";
        remotes = "remote --verbose";
        aliases = "config --get-regexp alias";
        credit = ''!f() { git commit --amend --author "$1 <$2>" -C HEAD; }; f'';
        dm = "!git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d";
        whoami = "config user.email";
      };
      "url \"git@github.com:\"".insteadOf = "gh:";
      "url \"git@gist.github.com:\"".insteadOf = "gst:";
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      aliases.co = "pr checkout";
      git_protocol = "ssh";
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "night-owlish";
      map-syntax = [ "*.js:JavaScript (Babel)" ];
    };
    themes.night-owlish = {
      src = pkgs.fetchFromGitHub {
        owner = "batpigandme";
        repo = "night-owlish";
        rev = "0ad95279de70";
        hash = "sha256-GcTMqig639fJxWk91lXSiGHjTfofkFOJEROZYzYWzfo=";
      };
      file = "tmTheme/night-owlish.tmTheme";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    sideloadInitLua = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
          set -g @resurrect-processes 'ssh'
        '';
      }
      {
        plugin = tmuxExposePlugin;
        extraConfig = ''
          set -g @tmux-expose-key 's'
          set -g @tmux-expose-key-table 'prefix'
          set -g @tmux-expose-width '100%'
          set -g @tmux-expose-height '60%'
          set -g @tmux-expose-anchor 'bottom'
          set -g @tmux-expose-style 'bg=colour234'
          set -g @tmux-expose-border-style 'fg=colour245'
        '';
      }
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style 'rounded'
          set -g @catppuccin_window_text ' #{?#{m/r:^[⠀-⣿],#{pane_title}},#{=1:pane_title} ,}#W'
          set -g @catppuccin_window_current_text ' #{?#{m/r:^[⠀-⣿],#{pane_title}},#{=1:pane_title} ,}#W'
        '';
      }
    ];
    extraConfig = builtins.readFile ../config/tmux/tmux.conf;
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
