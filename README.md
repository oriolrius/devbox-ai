# Devbox AI Cockpit

Portable SSH workspace: Devbox/Nix + Zellij + Zsh, with selectable profiles
(`base`, `ai`, `devops`, `full`). On this host it lives in `~/cockpit` and runs
the `ai` profile.

> Run commands via the aliases below. If an alias isn't loaded yet, prefix with
> `devbox run -c ~/cockpit/profiles/ai --` (e.g. `devbox run -c ~/cockpit/profiles/ai -- work`).

## Daily commands

```bash
work            # attach to the Zellij 'dev' session (creates it if absent)
work-ai         # same, forcing the ai profile      (aliases: work-ia)
work-devops     # switch to devops profile
work-full       # switch to full profile
work-reset      # DELETE the dev session and rebuild from the layout  ⚠ destructive
work-update     # git pull + reinstall shell/autostart + update active profile's tools
doctor          # check installed tools/versions for the active profile
profile-info    # show active profile and paths
```

AI tools (`ai`/`full` profiles):

```bash
claude          # Claude Code CLI        codex     # OpenAI Codex CLI
opencode        # OpenCode CLI           agent     # Pi
agy             # Antigravity CLI        gentle-ai # gentle-ai
workmux / wm    # worktree+agent multiplexer (wmz = force Zellij backend)
rtk gain        # accumulated token savings
```

## Keep your tabs across restarts  ← important

The cockpit drives one Zellij session named **`dev`**. How you leave it decides
whether your tabs survive:

- **`work` / `work-ai` attach** to `dev` if it exists — your runtime tabs/panes
  are preserved. They only build the fresh 2-tab layout when `dev` is gone.
- **`work-reset` is destructive by design**: it runs
  `zellij delete-session --force dev` and rebuilds from the layout template. Use
  it *only* when you want the clean base layout — never to "restart".
- **To restart while keeping everything: detach, don't exit.** Press
  `Ctrl+o` then `d`. The `dev` session stays alive in the background and the next
  `work`/`work-ai` reattaches exactly as you left it. Closing the terminal or
  `exit`-ing the panes ends the session.

**Survive a full reboot** (the Zellij server dies): session serialization is
enabled in `~/.config/zellij/config.kdl`:

```kdl
session_serialization  true
serialize_pane_viewport true
```

After a reboot the first `work` resurrects `dev` (tabs, cwds, running commands)
from `~/.cache/zellij`. Note: `work-reset` still purges the serialized copy too.

To make a customized tab arrangement the permanent default, dump it into the
layout template (heads-up: it's git-tracked, so a local edit will make
`work-update`'s `git pull` diverge):

```bash
zellij action dump-layout > ~/cockpit/config/zellij/layouts/dev.kdl.template
```

## Switch / update profiles

```bash
work --profile ia|devops|full       # or the work-* aliases
work-update --profile ia|devops|full # update-ia / update-devops / update-full
```

If a profile change touches the Zellij layout, reset from **outside** Zellij:

```bash
work --profile ia --reset
```

## Secrets (.env) — ai/full only

```bash
cd ~/cockpit
cp .env.example .env && nano .env      # Coolify / GitHub / etc. tokens
devbox run -c ~/cockpit/profiles/ai -- mcp-render   # renders ~/.pi/agent/mcp.json
```

`.env` is not committed. Template: `config/pi/mcp.template.json`.

## Reinstall a single piece

```bash
devbox run -c ~/cockpit/profiles/ai -- ai-clis            # codex/claude/opencode
devbox run -c ~/cockpit/profiles/ai -- rtk-install        # RTK
devbox run -c ~/cockpit/profiles/ai -- workmux-install    # Workmux
devbox run -c ~/cockpit/profiles/ai -- antigravity-install
devbox run -c ~/cockpit/profiles/ai -- zsh-install        # portable zsh
```

RTK hooks (token saving for agents). `rtk init -g` needs `~/.claude` to exist —
launch `claude` once first, or `mkdir -p ~/.claude` then:

```bash
rtk init -g --auto-patch    # Claude Code hook
rtk init -g --codex         # Codex hook
```

## Recover SSH if the autostart fails

The shell autostart drops you straight into Zellij. To get a plain shell, skip it:

```bash
ssh -t it@<host> 'ZELLIJ_AUTO_STARTED=1 bash -l'
```

Then, if needed, re-wire and rebuild from outside Zellij:

```bash
cd ~/cockpit && git pull
devbox run -c ~/cockpit/profiles/ai -- zellij-install
ZELLIJ_AUTO_STARTED=1 bash -lc 'devbox run -c ~/cockpit/profiles/ai -- work-reset'
```

## Notes

- Don't run `work`/`work-reset` from *inside* Zellij — it can be read as a new
  tab. Reset from a plain shell outside Zellij.
- `origin` here is the upstream `aitorroma/devbox-ai`; this README is kept local
  (marked `skip-worktree`) so `work-update` pulls don't conflict on it.
- Profiles: `base` (shell only), `ai` (+ Node + agent CLIs, **default here**),
  `devops` (+ infra toolpack), `full` (ai+devops). See `TOOLS.md`.
