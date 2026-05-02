if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

export GPG_TTY=$(tty)

gpg-auth() {
  if [[ "$1" == "-f" ]]; then
    gpg-connect-agent reloadagent /bye > /dev/null 2>&1
  fi
  gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
  echo "test" | gpg --clearsign -o /dev/null \
    && echo "✓ GPG authenticated" \
    || echo "✗ GPG auth failed"
}

if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
