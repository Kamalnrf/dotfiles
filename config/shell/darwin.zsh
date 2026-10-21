export CLICOLOR=1
export LSCOLORS=Fafacxdxbxegedabagacad
export CLAUDE_CODE_NO_FLICKER=1
export OPENCODE_EXPERIMENTAL_WORKSPACES=true

# Only Zsh's command-line editor handles these keys, not terminal applications.
bindkey -v
KEYTIMEOUT=10 # Hundredths of a second: keep Escape responsive.
bindkey -M viins '^C' vi-cmd-mode
bindkey -M visual '^C' deactivate-region
bindkey -M vicmd '^C' send-break

# Let ZLE receive Ctrl+C as a key at the prompt, but restore SIGINT for jobs.
vi_prompt_keys() {
  stty intr undef < /dev/tty
}
vi_job_keys() {
  stty intr '^C' < /dev/tty
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd vi_prompt_keys
add-zsh-hook preexec vi_job_keys
add-zsh-hook zshexit vi_job_keys

RPROMPT='%F{cyan}[INSERT]%f'
vi_mode_prompt() {
  local mode_prompt
  if (( REGION_ACTIVE )); then
    mode_prompt='%F{magenta}[VISUAL]%f'
  elif [[ $KEYMAP == vicmd ]]; then
    mode_prompt='%F{yellow}[NORMAL]%f'
  else
    mode_prompt='%F{cyan}[INSERT]%f'
  fi
  if [[ $RPROMPT != $mode_prompt ]]; then
    RPROMPT=$mode_prompt
    zle reset-prompt
  fi
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init vi_mode_prompt
add-zle-hook-widget line-pre-redraw vi_mode_prompt

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
