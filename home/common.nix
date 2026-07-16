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

  vtSrc = pkgs.fetchFromGitHub {
    owner = "val-town";
    repo = "vt";
    rev = "1eb64134b29ccec4c0465c8647f03e6edcfd7d22";
    hash = "sha256-XJfZ0wLW3QVfxZ1PaYX/n9+HIVnW1ZXALaoPsjxUnaM=";
  };

  vtDenoCache = pkgs.stdenvNoCC.mkDerivation {
    pname = "vt-deno-cache";
    version = "0.1.59";
    src = vtSrc;
    nativeBuildInputs = [ pkgs.deno pkgs.cacert pkgs.python3 ];
    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild
      export DENO_DIR="$out"
      export HOME="$TMPDIR/home"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      mkdir -p "$DENO_DIR" "$HOME"
      deno cache --frozen vt.ts
      rm -f "$DENO_DIR"/*_cache_v2*
      python3 - <<'PY'
      import json
      import os
      from pathlib import Path

      keep_headers = {
          "content-type",
          "location",
          "x-deno-warning",
          "x-typescript-types",
      }
      marker = b"\n// denoCacheMetadata="

      for path in (Path(os.environ["DENO_DIR"]) / "remote").rglob("*"):
          if not path.is_file():
              continue
          source, separator, raw_metadata = path.read_bytes().rpartition(marker)
          if not separator:
              continue
          metadata = json.loads(raw_metadata)
          metadata["headers"] = {
              key: value
              for key, value in metadata.get("headers", {}).items()
              if key.lower() in keep_headers
          }
          metadata["time"] = 0
          normalized = json.dumps(metadata, sort_keys=True, separators=(",", ":"))
          path.write_bytes(source + marker + normalized.encode())
      PY
      runHook postBuild
    '';
    installPhase = "true";

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = {
      aarch64-darwin = "sha256-0BXgb2cbCEWKI0DQOZsAqXhilUYWVixzNim1/AF48CA=";
      x86_64-linux = "sha256-+R4cfyIBDClwqkKow7+Yi05uA9ja/D6Ur1BNtW/WMCg=";
    }.${pkgs.stdenv.hostPlatform.system};
  };

  vt = pkgs.writeShellApplication {
    name = "vt";
    runtimeInputs = [ pkgs.coreutils pkgs.deno ];
    text = ''
      cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/vt"
      cache_dir="$cache_root/deno-0.1.59"

      if [[ ! -e "$cache_dir/.complete" ]]; then
        mkdir -p "$cache_root"
        rm -rf "$cache_dir"
        mkdir -p "$cache_dir"
        cp -R "${vtDenoCache}/." "$cache_dir/"
        chmod -R u+w "$cache_dir"
        touch "$cache_dir/.complete"
      fi

      export DENO_DIR="$cache_dir"
      export DENO_NO_UPDATE_CHECK=1
      exec deno run --cached-only -A "${vtSrc}/vt.ts" "$@"
    '';
    meta = {
      description = "Official CLI for the Val Town platform";
      homepage = "https://github.com/val-town/vt";
      license = lib.licenses.mit;
      mainProgram = "vt";
      platforms = [ "aarch64-darwin" "x86_64-linux" ];
    };
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
    vt
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
