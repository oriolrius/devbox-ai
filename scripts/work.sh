#!/usr/bin/env bash
set -euo pipefail

ROOT="${COCKPIT_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "$ROOT/scripts/profile-utils.sh"
CONFIG_DIR="${COCKPIT_DEVBOX_CONFIG:-${DEVBOX_PROJECT_ROOT:-$ROOT}}"
SESSION="${COCKPIT_HERDR_SESSION:-default}"
RESET=0
PROFILE_OVERRIDE=""
FORWARD_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset|reset)
      RESET=1
      FORWARD_ARGS+=("--reset")
      shift
      ;;
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "❌ Falta valor para --profile" >&2
        print_cockpit_profiles_help >&2
        exit 2
      fi
      PROFILE_OVERRIDE="$2"
      shift 2
      ;;
    --profile=*)
      PROFILE_OVERRIDE="${1#--profile=}"
      shift
      ;;
    -h|--help)
      cat <<'HELP'
Usage: work [--profile ia|devops|full|base] [--reset]

Attach to the cockpit Herdr default session, or create it if missing.
Use --profile to switch profiles before launching. `ia` and `ai` are aliases.
Use --reset to delete the existing session first so a fresh one is created.

Examples:
  work --profile ia
  work --profile devops --reset
  work --profile full
HELP
      exit 0
      ;;
    *)
      echo "Argumento desconocido: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -n "$PROFILE_OVERRIDE" ]]; then
  if ! TARGET_PROFILE="$(normalize_cockpit_profile "$PROFILE_OVERRIDE")"; then
    echo "❌ Perfil desconocido: $PROFILE_OVERRIDE" >&2
    print_cockpit_profiles_help >&2
    exit 2
  fi
  TARGET_CONFIG="$(cockpit_profile_config "$ROOT" "$TARGET_PROFILE")"
  if [[ ! -f "$TARGET_CONFIG/devbox.json" ]]; then
    echo "❌ No existe devbox.json para el perfil $TARGET_PROFILE en $TARGET_CONFIG" >&2
    exit 1
  fi
  if [[ "$TARGET_CONFIG" != "$CONFIG_DIR" ]]; then
    echo "🔁 Cambiando a perfil '$TARGET_PROFILE'..."
    exec devbox run -c "$TARGET_CONFIG" -- bash "$ROOT/scripts/work.sh" "${FORWARD_ARGS[@]}"
  fi
fi

cd "$ROOT"

# Use normal terminal panes, not command panes. Herdr opens $SHELL for bare panes.
if command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
else
  export SHELL="$(command -v bash)"
fi
export COCKPIT_HOME="${COCKPIT_HOME:-$ROOT}"

if [[ -n "${HERDR_ENV:-}" ]]; then
  if [[ "$RESET" == 1 ]]; then
    cat >&2 <<MSG
⚠️  Estás dentro de Herdr. No ejecuto work-reset desde dentro.

   Hazlo desde fuera de Herdr:
     bash -lc 'cd "$ROOT" && devbox run -c "$CONFIG_DIR" -- bash "$ROOT/scripts/work.sh" --reset'
MSG
    exit 2
  fi
  echo "ℹ️  Ya estás dentro de Herdr. Detach con tu keybinding o work-reset desde fuera."
  exit 0
fi

if [[ "$RESET" == 1 ]]; then
  herdr session delete "$SESSION" >/dev/null 2>&1 || true
fi

# Bare `herdr` launches or attaches to the default persistent session; a named
# session goes through the same launch-or-attach path with --session.
if [[ "$SESSION" == "default" ]]; then
  exec herdr
fi
exec herdr --session "$SESSION"
