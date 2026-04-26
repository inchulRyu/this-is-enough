# Installing ThisIsEnough (`tie`) for Codex CLI

Codex discovers skills natively from `~/.agents/skills/`. Install by cloning the repo
and creating a symlink — no plugin manager needed.

## Prerequisites

- Git
- Codex CLI

## Installation

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

```bash
ls -la ~/.agents/skills/tie
```

You should see a symlink (or junction on Windows) into the cloned `skills/` directory.

Inside Codex, type `/skills` or `$tie:` — you should see `tie:orchestrator`,
`tie:planner`, `tie:generator`, `tie:evaluator`, `tie:resume`, `tie:status`.

## Usage

In a Codex session, kick off the workflow once:

```
$tie:orchestrator I want to build <your requirement here>
```

The orchestrator handles everything from there. It will only stop on a real blocker
(critical decision needed, environment broken, repeated unrecoverable failure) or
when the project is complete. To resume after a session ends:

```
$tie:resume
```

To check status without taking action:

```
$tie:status
```

## Updating

```bash
cd ~/.codex/thisisenough && git pull
```

The symlink picks up changes instantly. Restart Codex if a session is open.

## Uninstalling

```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough   # optional, removes the clone
```
