#!/bin/bash
# Raise the existing work-ai kitty window if one is running, otherwise launch it.
set -euo pipefail

win=$(xdotool search --name "^work-ai$" 2>/dev/null | head -1 || true)

if [ -n "$win" ]; then
    xdotool windowactivate "$win"
else
    exec kitty --title work-ai /usr/local/bin/devbox run -c /home/it/cockpit/profiles/ai -- bash /home/it/cockpit/scripts/work.sh --profile ia
fi
