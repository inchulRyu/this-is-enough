#!/usr/bin/env bash
# Install ThisIsEnough (`tie`) for Codex CLI.
# Idempotent: re-running updates the clone and refreshes the symlink.
#
# Usage:
#   curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
#
# Override defaults via env vars:
#   TIE_REPO_URL    git URL to clone (default: github.com/inchulRyu/this-is-enough)
#   TIE_CLONE_DIR   where to clone     (default: $HOME/.codex/thisisenough)
#   TIE_SKILL_LINK  symlink to create  (default: $HOME/.agents/skills/tie)

set -euo pipefail

REPO_URL="${TIE_REPO_URL:-https://github.com/inchulRyu/this-is-enough.git}"
CLONE_DIR="${TIE_CLONE_DIR:-$HOME/.codex/thisisenough}"
SKILL_LINK="${TIE_SKILL_LINK:-$HOME/.agents/skills/tie}"

err() { printf 'error: %s\n' "$*" >&2; exit 1; }
log() { printf '==> %s\n' "$*"; }

command -v git >/dev/null 2>&1 || err "git is required but not found in PATH"

if [ -d "$CLONE_DIR/.git" ]; then
  log "Updating existing clone at $CLONE_DIR"
  git -C "$CLONE_DIR" fetch --prune origin
  git -C "$CLONE_DIR" reset --hard origin/main
elif [ -e "$CLONE_DIR" ]; then
  err "$CLONE_DIR exists but is not a git clone — refusing to overwrite"
else
  log "Cloning $REPO_URL into $CLONE_DIR"
  mkdir -p "$(dirname "$CLONE_DIR")"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

mkdir -p "$(dirname "$SKILL_LINK")"

if [ -L "$SKILL_LINK" ]; then
  current_target="$(readlink "$SKILL_LINK")"
  if [ "$current_target" = "$CLONE_DIR/skills" ]; then
    log "Symlink already points at $CLONE_DIR/skills"
  else
    log "Replacing symlink (was $current_target)"
    rm "$SKILL_LINK"
    ln -s "$CLONE_DIR/skills" "$SKILL_LINK"
  fi
elif [ -e "$SKILL_LINK" ]; then
  err "$SKILL_LINK exists and is not a symlink — refusing to overwrite"
else
  log "Creating symlink $SKILL_LINK -> $CLONE_DIR/skills"
  ln -s "$CLONE_DIR/skills" "$SKILL_LINK"
fi

log "Done. Restart Codex (quit and relaunch) so it picks up the skills."
log "Verify: ls -la \"$SKILL_LINK\""
