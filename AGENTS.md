# Agent Instructions

This repository provides `codex-tmux-title`, a small Codex hook command
that renames the current tmux window to the active Codex thread title.

## Install For A User

Use these steps when a user asks you to install or set up this package.

1. Confirm the user wants a user-level install unless they explicitly ask for a
   project-local setup.
2. Install the script to an absolute path:

   ```sh
   mkdir -p "$HOME/.local/bin"
   install -m 0755 bin/codex-tmux-title "$HOME/.local/bin/codex-tmux-title"
   ```

3. Add a Codex hook configuration using that absolute path. Prefer appending to
   `~/.codex/hooks.json` or a trusted project `.codex/hooks.json` instead of
   editing complex existing TOML by hand.
4. Ensure `[features] codex_hooks = true` is present in the active Codex config.
5. Keep the hook timeout short: `2` seconds.
6. Do not install session or pane hooks. This package is window-only.

## Hook Configuration

The intended hook events are:

- `SessionStart`: name the tmux window on startup or resume.
- `Stop`: update the tmux window after each completed turn.

Recommended TOML shape:

```toml
[features]
codex_hooks = true

[[hooks.SessionStart]]
matcher = "startup|resume"

[[hooks.SessionStart.hooks]]
type = "command"
command = "/Users/alice/.local/bin/codex-tmux-title"
timeout = 2

[[hooks.Stop]]
[[hooks.Stop.hooks]]
type = "command"
command = "/Users/alice/.local/bin/codex-tmux-title"
timeout = 2
```

Replace `/Users/alice/.local/bin/codex-tmux-title` with the user's actual
absolute install path.

## Safety Rules

- Do not use a relative command path in hook config.
- Do not rely on `PATH` in hook config.
- Do not broaden the package to rename tmux sessions or panes unless the user
  explicitly asks for that feature.
- Do not read credentials, network resources, or arbitrary Codex logs.
- The only intended side effect is `tmux rename-window`.
- If the user already has hooks, preserve them. Codex runs matching hooks from
  multiple sources, so add this hook without removing unrelated hooks.

## Verification

After setup, verify:

```sh
~/.local/bin/codex-tmux-title --print < test/fixtures/hook-stop.json
./test/run-tests.sh
```

For a live check, the user should start or resume Codex inside tmux. The window
should become the Codex thread title after `SessionStart` or after the next
completed turn.
