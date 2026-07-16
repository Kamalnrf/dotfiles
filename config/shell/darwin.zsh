export CLICOLOR=1
export LSCOLORS=Fafacxdxbxegedabagacad
export CLAUDE_CODE_NO_FLICKER=1
export OPENCODE_EXPERIMENTAL_WORKSPACES=true

o() {
  if [[ $# -eq 0 ]]; then
    open .
  else
    open "$@"
  fi
}

quit() {
  if [[ -z "${1:-}" ]]; then
    echo "Usage: quit appname"
    return 1
  fi

  local appname
  for appname in "$@"; do
    osascript -e "quit app \"$appname\""
  done
}

export ANDROID_HOME="$HOME/Library/Android/sdk"
path+=(
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/tools"
  "$ANDROID_HOME/tools/bin"
  "$ANDROID_HOME/platform-tools"
)

[[ -r "$HOME/.deno/env" ]] && source "$HOME/.deno/env"
[[ -r "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
[[ -r "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
