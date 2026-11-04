#!/usr/bin/env bash
# Default shell for herdr panes.
#
# The herdr server is long-lived and is usually started from a plain login
# shell, so panes it spawns do NOT inherit the work-ai (devbox/nix) env. This
# wrapper drops each new pane into the cockpit devbox env and then hands off to
# the user's interactive shell, so panes launched via `work-ai` actually land
# inside the work-ai environment.
#
# Idempotent: if we're already inside the devbox env (nested panes/subshells)
# we skip straight to the shell. Falls back to a plain shell when devbox or the
# profile config is unavailable.

set -u

COCKPIT_HOME="${COCKPIT_HOME:-/home/it/cockpit}"
COCKPIT_DEVBOX_CONFIG="${COCKPIT_DEVBOX_CONFIG:-$COCKPIT_HOME/profiles/ai}"

if command -v zsh >/dev/null 2>&1; then
  real_shell="$(command -v zsh)"
else
  real_shell="$(command -v bash)"
fi

if [[ -z "${DEVBOX_SHELL_ENABLED:-}" ]] \
   && [[ -f "$COCKPIT_DEVBOX_CONFIG/devbox.json" ]] \
   && command -v devbox >/dev/null 2>&1; then
  export COCKPIT_HOME COCKPIT_DEVBOX_CONFIG
  exec devbox run -c "$COCKPIT_DEVBOX_CONFIG" -- "$real_shell" -l
fi

exec "$real_shell" -l
