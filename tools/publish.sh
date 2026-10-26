#!/usr/bin/env bash
set -euo pipefail
STEEL_SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$STEEL_SOURCE_DIR"
PYTHONDONTWRITEBYTECODE=1 python3 tools/audit-export.py
if ! command -v gh >/dev/null; then printf '%s\n' 'Install github-cli and run gh auth login.' >&2; exit 1; fi
gh auth status
STEEL_ORIGIN="$(git remote get-url origin)"
case "$STEEL_ORIGIN" in
 https://github.com/*) STEEL_REPO="${STEEL_ORIGIN#https://github.com/}" ;;
 git@github.com:*) STEEL_REPO="${STEEL_ORIGIN#git@github.com:}" ;;
 *) printf '%s\n' 'Expected a GitHub origin remote.' >&2; exit 1 ;;
esac
STEEL_REPO="${STEEL_REPO%.git}"
STEEL_IS_FORK="$(gh api "repos/$STEEL_REPO" --jq '.fork and (.parent.full_name == "end-4/dots-hyprland") and (.visibility == "public")')"
if [[ "$STEEL_IS_FORK" != true ]]; then printf '%s\n' 'Expected a public fork of end-4/dots-hyprland; stopped.' >&2; exit 1; fi
if [[ -n "$(git status --porcelain)" ]]; then printf '%s\n' 'Commit reviewed source changes before publishing.' >&2; exit 1; fi
git push origin HEAD:refs/heads/main
