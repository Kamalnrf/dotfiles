export CLICOLOR=1
export LSCOLORS=Fafacxdxbxegedabagacad
export CLAUDE_CODE_NO_FLICKER=1
export OPENCODE_EXPERIMENTAL_WORKSPACES=true

git_branch() {
  git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\ \(\1\)/'
}

random_element() {
  local -a elements=("$@")
  printf "%s\n" "${elements[$((RANDOM % $# + 1))]}"
}

setEmoji() {
  local emoji="$*"
  PROMPT='%F{yellow}%~%F{green}$(git_branch)%f '"$emoji"$'\n$ '
}

newRandomEmoji() {
  setEmoji "$(random_element 😅 👽 🔥 🚀 👻 ⛄ 👾 🍔 😄 🍰 🐑 😎 🏎 🤖 😇 😼 💪 🦄 🥓 🌮 🎉 💯 ⚛️ 🐠 🐳 🐿 🥳 🤩 🤯 🤠 👨‍💻 🦸‍ 🧝‍ 🧞‍ 🧙‍ 👨‍🚀 👨‍🔬 🕺 🦁 🐶 🐵 🐻 🦊 🐙 🦎 🦖 🦕 🦍 🦈 🐊 🦂 🐍 🐢 🐘 🐉 🦚 ✨ ☄️ ⚡️ 💥 💫 🧬 🔮 ⚗️ 🎊 🔭 ⚪️ 🔱)"
}

setopt promptsubst
newRandomEmoji

alias jestify="PROMPT=\"🃏\"$'\n'\"$ \""
alias testinglibify="PROMPT=\"🐙\"$'\n'\"$ \""
alias cypressify="PROMPT=\"🌀\"$'\n'\"$ \""
alias staticify="PROMPT=\"🚀\"$'\n'\"$ \""
alias nodeify="PROMPT=\"💥\"$'\n'\"$ \""
alias reactify="PROMPT=\"⚛️\"$'\n'\"$ \""
alias harryify="PROMPT=\"🧙‍\"$'\n'\"$ \""

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
