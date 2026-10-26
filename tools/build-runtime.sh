#!/usr/bin/env bash
set -euo pipefail
ARC_STEEL_SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ARC_STEEL_BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/arc-steel-build/quickshell"
ARC_STEEL_QS_REV="4f508be500dea6e5732cc3d50382a0048b17e7b1"
ARC_STEEL_DEST="${1:?Pass the output executable path}"
mkdir -p "$(dirname -- "$ARC_STEEL_BUILD_DIR")" "$(dirname -- "$ARC_STEEL_DEST")"
if [[ ! -d "$ARC_STEEL_BUILD_DIR/.git" ]]; then
 git clone https://github.com/quickshell-mirror/quickshell.git "$ARC_STEEL_BUILD_DIR"
fi
if [[ "$(git -C "$ARC_STEEL_BUILD_DIR" rev-parse HEAD)" != "$ARC_STEEL_QS_REV" ]]; then
 if [[ -n "$(git -C "$ARC_STEEL_BUILD_DIR" status --porcelain)" ]]; then
  printf '%s\n' 'Build checkout has changes; preserve it and use a fresh cache directory.' >&2; exit 1
 fi
 git -C "$ARC_STEEL_BUILD_DIR" checkout --detach "$ARC_STEEL_QS_REV"
fi
if git -C "$ARC_STEEL_BUILD_DIR" apply --check "$ARC_STEEL_SOURCE_DIR/web-runtime/source.patch"; then
 git -C "$ARC_STEEL_BUILD_DIR" apply "$ARC_STEEL_SOURCE_DIR/web-runtime/source.patch"
elif ! git -C "$ARC_STEEL_BUILD_DIR" apply --reverse --check "$ARC_STEEL_SOURCE_DIR/web-runtime/source.patch"; then
 printf '%s\n' 'Runtime patch does not match the pinned source.' >&2;exit 1
fi
cmake -S "$ARC_STEEL_BUILD_DIR" -B "$ARC_STEEL_BUILD_DIR/build-arc-steel" -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCRASH_HANDLER=OFF -DDISTRIBUTOR=Steel \
 -DCRASHREPORT_URL=https://github.com/serpiero/dots-hyprland/issues
cmake --build "$ARC_STEEL_BUILD_DIR/build-arc-steel" --parallel "${ARC_STEEL_BUILD_JOBS:-2}"
install -m755 "$ARC_STEEL_BUILD_DIR/build-arc-steel/src/quickshell" "$ARC_STEEL_DEST"
