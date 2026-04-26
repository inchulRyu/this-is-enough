# Installing ThisIsEnough (`tie`) for Codex CLI

Codex CLI 0.125+ has a built-in plugin marketplace and accepts our
`.claude-plugin/marketplace.json` directly — that's the easiest path. Older
Codex builds only support `~/.agents/skills/` discovery; Options B and C
handle that.

## Prerequisites

- Codex CLI (0.125+ for Option A; any version for B/C)
- Git

## Option A — Codex plugin marketplace (recommended, 0.125+)

```bash
codex plugin marketplace add inchulRyu/this-is-enough
```

This writes a `[marketplaces.thisisenough]` entry to `~/.codex/config.toml`
and clones the marketplace into `~/.codex/.tmp/marketplaces/thisisenough`.

Launch `codex`, open the plugin picker, and enable **tie@thisisenough**. The
`tie:*` skills become available in your sessions.

To update later:

```bash
codex plugin marketplace upgrade thisisenough
```

To remove:

```bash
codex plugin marketplace remove thisisenough
```

## Option B — Skill symlink one-liner (older Codex, or no marketplace)

```bash
curl -fsSL https://raw.githubusercontent.com/inchulRyu/this-is-enough/main/install-codex.sh | bash
```

The script clones to `~/.codex/thisisenough` and symlinks
`~/.agents/skills/tie`. Re-run it any time to update — it's idempotent. Then
restart Codex.

## Option C — Manual clone + symlink

Use this on Windows, or when you want to see every step.

1. **Clone the repo:**
   ```bash
   git clone https://github.com/inchulRyu/this-is-enough.git ~/.codex/thisisenough
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/thisisenough/skills ~/.agents/skills/tie
   ```

   **Windows (PowerShell, no Developer Mode required):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills" | Out-Null
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\tie" "$env:USERPROFILE\.codex\thisisenough\skills"
   ```

3. **Restart Codex** (quit and relaunch) so it picks up the new skills.

## Verify

Inside Codex, type `$tie:` and you should see `tie:orchestrator`,
`tie:planner`, `tie:generator`, `tie:evaluator`, `tie:resume`, `tie:status`.

For Options B/C you can also confirm the symlink directly:

```bash
ls -la ~/.agents/skills/tie
```

You should see a symlink (or junction on Windows) into the cloned `skills/`
directory.

## Usage

In a Codex session, kick off the workflow once:

```
$tie:orchestrator I want to build <your requirement here>
```

The orchestrator handles everything from there. It will only stop on a real
blocker (critical decision needed, environment broken, repeated unrecoverable
failure) or when the project is complete. To resume after a session ends:

```
$tie:resume
```

To check status without taking action:

```
$tie:status
```

## Updating

- **Option A:** `codex plugin marketplace upgrade thisisenough`
- **Option B:** rerun the `install-codex.sh` one-liner
- **Option C:** `cd ~/.codex/thisisenough && git pull` (the symlink picks up
  changes instantly; restart Codex if a session is open)

## Uninstalling

**Option A:**
```bash
codex plugin marketplace remove thisisenough
```

**Options B / C:**
```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough   # optional, removes the clone
```
