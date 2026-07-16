# Shared interactive shell functions. Keep this valid in Bash and Zsh.

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

git_branch() {
  git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\ \(\1\)/'
}

random_element() {
  local index=$((RANDOM % $# + 1))
  while [[ $index -gt 1 ]]; do
    shift
    index=$((index - 1))
  done
  printf "%s\n" "$1"
}

setEmoji() {
  local emoji="$*"
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    PROMPT='%F{yellow}%~%F{green}$(git_branch)%f '"$emoji"$'\n$ '
  else
    PS1='\[\e[33m\]\w\[\e[32m\]$(git_branch)\[\e[0m\] '"$emoji"$'\n$ '
  fi
}

newRandomEmoji() {
  setEmoji "$(random_element 😅 👽 🔥 🚀 👻 ⛄ 👾 🍔 😄 🍰 🐑 😎 🏎 🤖 😇 😼 💪 🦄 🥓 🌮 🎉 💯 ⚛️ 🐠 🐳 🐿 🥳 🤩 🤯 🤠 👨‍💻 🦸‍ 🧝‍ 🧞‍ 🧙‍ 👨‍🚀 👨‍🔬 🕺 🦁 🐶 🐵 🐻 🦊 🐙 🦎 🦖 🦕 🦍 🦈 🐊 🦂 🐍 🐢 🐘 🐉 🦚 ✨ ☄️ ⚡️ 💥 💫 🧬 🔮 ⚗️ 🎊 🔭 ⚪️ 🔱)"
}

if [[ -n "${ZSH_VERSION:-}" ]]; then
  setopt promptsubst
fi
newRandomEmoji

alias jestify="setEmoji 🃏"
alias testinglibify="setEmoji 🐙"
alias cypressify="setEmoji 🌀"
alias staticify="setEmoji 🚀"
alias nodeify="setEmoji 💥"
alias reactify="setEmoji ⚛️"
alias harryify="setEmoji 🧙‍"

mkd() {
  mkdir -p "$@" && cd "$_"
}

fs() {
  local arg
  if du -b /dev/null >/dev/null 2>&1; then
    arg=-sbh
  else
    arg=-sh
  fi

  if [[ $# -gt 0 ]]; then
    du "$arg" -- "$@"
  else
    du "$arg" .[^.]* ./*
  fi
}

if command -v git >/dev/null 2>&1; then
  diff() {
    git diff --no-index --color-words "$@"
  }
fi

gz() {
  local origsize gzipsize ratio
  origsize=$(wc -c <"$1")
  gzipsize=$(gzip -c "$1" | wc -c)
  ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l)
  printf "orig: %d bytes\n" "$origsize"
  printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

tattach() {
  local restore_session="__restore"
  local target_session
  local tmux_socket
  local restore_output
  local resurrect_dir
  local resurrect_file
  local restore_script="${TMUX_RESURRECT_RESTORE:-$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh}"

  target_session=$(tmux list-sessions -F '#S' 2>/dev/null | grep -vx "$restore_session" | head -n 1)

  if [[ -z "$target_session" ]]; then
    tmux new-session -d -s "$restore_session" 2>/dev/null || true
    resurrect_dir=$(tmux show-option -gqv '@resurrect-dir')
    if [[ -z "$resurrect_dir" ]]; then
      if [[ -d "$HOME/.tmux/resurrect" ]]; then
        resurrect_dir="$HOME/.tmux/resurrect"
      else
        resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
      fi
    fi
    resurrect_dir=${resurrect_dir/#\~/$HOME}
    resurrect_dir=${resurrect_dir//\$HOME/$HOME}
    resurrect_dir=${resurrect_dir//\$HOSTNAME/$(hostname)}
    resurrect_file="$resurrect_dir/last"

    if [[ ! -s "$resurrect_file" || ! -x "$restore_script" ]]; then
      tmux kill-session -t "$restore_session" 2>/dev/null || true
      tmux-project-popup "$PWD"
      return
    fi

    tmux_socket=$(tmux display-message -p -t "$restore_session" '#{socket_path}')
    restore_output=$(TMUX="$tmux_socket,0,0" "$restore_script" 2>&1)
    target_session=$(tmux list-sessions -F '#S' 2>/dev/null | grep -vx "$restore_session" | head -n 1)
    if [[ -z "$target_session" && -n "$restore_output" ]]; then
      printf '%s\n' "$restore_output" >&2
    fi
  fi

  if [[ -z "$target_session" ]]; then
    tmux kill-session -t "$restore_session" 2>/dev/null || true
    tmux-project-popup "$PWD"
    return
  fi

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$target_session"
  else
    tmux attach -t "$target_session"
  fi

  tmux kill-session -t "$restore_session" 2>/dev/null || true
}

getcertnames() {
  if [[ -z "${1:-}" ]]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="$1"
  local tmp cert_text
  echo "Testing ${domain}…"
  echo
  tmp=$(printf "GET / HTTP/1.0\nEOT\n" | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1)

  if [[ "$tmp" == *"-----BEGIN CERTIFICATE-----"* ]]; then
    cert_text=$(printf '%s\n' "$tmp" | openssl x509 -text -certopt "no_aux,no_header,no_issuer,no_pubkey,no_serial,no_sigdump,no_signame,no_validity,no_version")
    echo "Common Name:"
    echo
    printf '%s\n' "$cert_text" | grep "Subject:" | sed -e "s/^.*CN=//" -e "s/\/emailAddress=.*//"
    echo
    echo "Subject Alternative Name(s):"
    echo
    printf '%s\n' "$cert_text" | grep -A 1 "Subject Alternative Name:" | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

killport() {
  lsof -i tcp:"$*" | awk 'NR!=1 {print $2}' | xargs kill -9
}
