# codex-tmux-title

Rename the current tmux window to the current Codex thread title.

This package is intentionally small: it supports tmux windows only. The tmux
session should remain your project or workspace, while the tmux window tracks
the active Codex thread.

## Requirements

- Codex with lifecycle hooks enabled
- tmux
- `jq`
- `sqlite3`

## Install

Clone the repository and put `bin/` on your `PATH`:

```sh
git clone https://github.com/rummalaneni/codex-tmux-title.git
cd codex-tmux-title
export PATH="$PWD/bin:$PATH"
```

For a local install:

```sh
mkdir -p ~/.local/bin
install -m 0755 bin/codex-tmux-title ~/.local/bin/codex-tmux-title
```

## Codex Hook Setup

Add this to `~/.codex/config.toml` or a trusted project `.codex/config.toml`:

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

Replace `/Users/alice/.local/bin/codex-tmux-title` with the absolute path
where you installed the script. An absolute path avoids accidentally running a
different command with the same name from `PATH`.

`SessionStart` names the window when a thread starts or resumes. `Stop` updates
it again after each turn, once Codex may have generated or changed the title.

## How It Works

Codex sends hook metadata as JSON on stdin. The script reads `session_id`, looks
up the matching thread title in Codex local state, sanitizes it for tmux, and
runs:

```sh
tmux rename-window "$title"
```

If the title cannot be found in the Codex session index, it falls back to the
Codex SQLite state, then to the Codex session id. If no session id is available,
it exits successfully without renaming the window.

The script exits successfully without doing anything when it is not running
inside tmux.

## Debugging

Print the resolved title without touching tmux:

```sh
codex-tmux-title --print < test/fixtures/hook-stop.json
```

Show the tmux command that would run:

```sh
codex-tmux-title --dry-run < test/fixtures/hook-stop.json
```

## Environment

These variables are optional and mainly useful for tests:

- `CODEX_HOME`: defaults to `~/.codex`
- `CODEX_STATE_DB`: path to the Codex SQLite state database
- `CODEX_SESSION_INDEX`: path to `session_index.jsonl`
- `CODEX_THREAD_ID`: fallback thread id for manual runs

## Design Principles

- Window-only behavior.
- No network access.
- No credential access.
- Read-only Codex metadata access.
- Silent success on missing tmux, missing Codex state, or transient failures.
- Short hook timeout recommended: `2` seconds.

## Coding Agents

If you are a coding agent helping someone install this package, follow
[AGENTS.md](AGENTS.md). It keeps setup user-scoped, uses absolute hook paths,
and preserves existing Codex hooks.

## License

MIT
