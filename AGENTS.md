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
4. Ensure `[features] hooks = true` is present in the active Codex config.
   Do not use the older `codex_hooks` flag name for current Codex builds.
5. Keep the hook timeout short: `2` seconds.
6. Do not install session or pane hooks. This package is window-only.

## Codex Hooks vs This Hook Command

Codex hooks are the Codex lifecycle feature that runs configured commands when
events happen. `codex-tmux-title` is only one command that Codex hooks can run.
Installing the script is not enough by itself: the user also needs Codex hooks
enabled and a hook entry that points at the installed script.

## Hook Configuration

The intended hook events are:

- `SessionStart`: name the tmux window on startup or resume.
- `UserPromptSubmit`: update the tmux window when the user submits a prompt.

Recommended `~/.codex/hooks.json` shape:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/alice/.local/bin/codex-tmux-title",
            "timeout": 2
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/alice/.local/bin/codex-tmux-title",
            "timeout": 2
          }
        ]
      }
    ]
  }
}
```

Replace `/Users/alice/.local/bin/codex-tmux-title` with the user's actual
absolute install path.

The active Codex config still needs hooks enabled:

```toml
[features]
hooks = true
```

## Title Resolution

The command resolves the tmux window title in this order:

1. `session_index.jsonl` thread name.
2. SQLite thread title from `state_5.sqlite`.
3. The Codex `session_id`.
4. No rename when no session id is available.

Do not fall back to the working directory, project name, or existing tmux window
name. If there is no Codex title yet, the intended visible fallback is the
session id.

Codex currently provides lifecycle hooks such as startup/resume, prompt submit,
and completed turn, not a dedicated "thread title changed" hook. A changed
Codex title is reflected after the next matching hook event, usually
`UserPromptSubmit`, or after a later resume.

## Safety Rules

- Do not use a relative command path in hook config.
- Do not rely on `PATH` in hook config.
- Do not put project-local or untrusted directories ahead of system directories
  in the hook process `PATH`; the script invokes helper tools such as `jq`,
  `sqlite3`, and `tmux`.
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

For a live check, the user should start or resume Codex inside tmux, or submit a
prompt in an existing Codex thread. The window should become the Codex thread
title after `SessionStart` or when `UserPromptSubmit` runs. If the title has not
been generated yet, the window should show the Codex session id.
