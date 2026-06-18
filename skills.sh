#!/usr/bin/env bash
#
# skills.sh — install jedymatt's Claude Code skills.
#
# The repo is the source of truth. Installing symlinks each skill in ./skills/
# into your Claude skills directory, so edits in the repo go live immediately.
#
# Usage:
#   ./skills.sh install     Symlink every skill into the Claude skills dir
#   ./skills.sh list        Show each skill and whether it is linked
#   ./skills.sh uninstall   Remove only the symlinks this script created
#   ./skills.sh help        Show this message
#
# Override the target directory with CLAUDE_SKILLS_DIR (defaults to
# ~/.claude/skills).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

# --- output helpers ---

info()  { printf '  %s\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
fail()  { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; }

# --- discovery ---

skill_names() {
  find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

# A target is "ours" only if it is a symlink already pointing into this repo.
links_into_repo() {
  local target="$1"
  [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$SKILLS_SRC/"* ]]
}

# --- install ---

backup_existing() {
  local target="$1"
  local backup="$target.bak.$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  warn "moved existing $(basename "$target") aside → $(basename "$backup")"
}

link_skill() {
  local name="$1"
  local target="$SKILLS_DEST/$name"

  if links_into_repo "$target"; then
    ok "$name (already linked)"
    return
  fi

  [[ -e "$target" || -L "$target" ]] && backup_existing "$target"

  ln -s "$SKILLS_SRC/$name" "$target"
  ok "$name"
}

install_skills() {
  mkdir -p "$SKILLS_DEST"
  info "Installing into $SKILLS_DEST"
  local name
  while IFS= read -r name; do
    link_skill "$name"
  done < <(skill_names)
}

# --- uninstall ---

unlink_skill() {
  local name="$1"
  local target="$SKILLS_DEST/$name"

  if links_into_repo "$target"; then
    rm "$target"
    ok "removed $name"
  elif [[ -e "$target" ]]; then
    warn "skipped $name (not a link this script made)"
  else
    info "$name (not installed)"
  fi
}

uninstall_skills() {
  info "Removing links in $SKILLS_DEST"
  local name
  while IFS= read -r name; do
    unlink_skill "$name"
  done < <(skill_names)
}

# --- list ---

print_status() {
  local name="$1"
  local target="$SKILLS_DEST/$name"

  if links_into_repo "$target"; then
    ok "$name — linked"
  elif [[ -e "$target" || -L "$target" ]]; then
    warn "$name — exists but not linked here"
  else
    info "$name — not installed"
  fi
}

list_skills() {
  info "Skills in $SKILLS_SRC"
  local name
  while IFS= read -r name; do
    print_status "$name"
  done < <(skill_names)
}

# --- entry point ---

usage() {
  sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

main() {
  local command="${1:-install}"
  case "$command" in
    install)   install_skills ;;
    uninstall) uninstall_skills ;;
    list)      list_skills ;;
    help|-h|--help) usage ;;
    *) fail "unknown command: $command"; usage; exit 1 ;;
  esac
}

main "$@"
