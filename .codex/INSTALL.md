# Installing ThisIsEnough (`tie`) for Codex CLI

Codex currently loads ThisIsEnough most reliably through native skill discovery
from `~/.agents/skills/`. The installer below clones the repo and creates that
skill link.

## Prerequisites

- Codex CLI
- Git
- `curl`

## Install

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

The script:

- clones or updates ThisIsEnough at `~/.codex/thisisenough`
- syncs the managed clone to `origin/main`
- creates `~/.agents/skills/tie -> ~/.codex/thisisenough/skills`

Restart Codex after installation.

## Verify

Inside Codex, type:

```text
$tie:
```

You should see:

```text
tie:requirements
tie:orchestrator
tie:planner
tie:generator
tie:evaluator
tie:resume
tie:status
tie:doctor
```

You can also confirm the symlink directly:

```bash
ls -la ~/.agents/skills/tie
```

## Update

Re-run the same installer:

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

Then restart Codex if a session is already open.

The installer treats `~/.codex/thisisenough` as a managed clone. If that clone
has local edits or diverged commits, the installer refuses to overwrite them;
commit/stash those changes or set `TIE_CLONE_DIR` to a fresh managed location.

## Uninstall

```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough
```

Then restart Codex.

## Note on Codex Marketplace

`codex plugin marketplace add inchulRyu/this-is-enough` currently registers and
clones the marketplace, but may not complete the plugin cache/install step that
makes `$tie:` available in Codex. Until that flow is reliable, the installer
above is the recommended Codex path.
