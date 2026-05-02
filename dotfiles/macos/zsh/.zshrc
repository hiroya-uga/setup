if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

export GPG_TTY=$(tty)

gpg-auth() {
  emulate -L zsh
  local gpg_status=0 gpg_out log=""

  _restart_agent() {
    gpgconf --kill all > /dev/null 2>&1 || true
    gpgconf --launch gpg-agent > /dev/null 2>&1 || true
    gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1 || true
  }

  _sign_test() {
    log=$(mktemp "${TMPDIR:-/tmp}/gpg-auth.XXXXXX")
    print -r -- test | gpg --clearsign -o /dev/null 2>"$log"
    gpg_status=$?
    gpg_out=$(<"$log")
    rm -f "$log"; log=""
  }

  {
    if [[ ${1:-} == -f ]]; then
      _restart_agent
    else
      gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1 || true
    fi

    _sign_test
    if [[ $gpg_out == *"server 'keyboxd' is older than us"* ]]; then
      echo "Restarting outdated GnuPG daemons ..." >&2
      _restart_agent
      _sign_test
    fi

    [[ -n $gpg_out ]] && print -r -- "$gpg_out" >&2
    (( gpg_status == 0 ))   && { echo "✓ GPG authenticated"; return 0; }
    (( gpg_status == 130 )) && { echo "GPG authentication canceled" >&2; return 130; }
    echo "✗ GPG auth failed" >&2
    return $gpg_status
  } always {
    [[ -n $log && -f $log ]] && rm -f "$log"
    unfunction _restart_agent _sign_test 2>/dev/null
  }
}

if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
