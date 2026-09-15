#!/bin/sh
# Install the newest pre-SSE4.2 Bun ("barcelona") build from GitHub Releases.
#
#   curl -fsSL https://raw.githubusercontent.com/tilly182/bun-no-sse4.2-nya/main/install.sh | sh
#
# POSIX sh, needs curl + tar. No bash, no bun, no root.
#
# Env:
#   BARCELONA_REPO=owner/repo     release source   (default tilly182/bun-no-sse4.2-nya)
#   BARCELONA_TAG=v1.4.2-barcelona                  pin a release instead of newest
#   BARCELONA_HOME=$HOME/.bun-barcelona             install dir
#   BARCELONA_BIN=$HOME/.local/bin                  where the `bun` symlink goes ('' = skip)
#   BARCELONA_DRY=1                                 resolve + print, install nothing

set -eu

REPO=${BARCELONA_REPO:-tilly182/bun-no-sse4.2-nya}
HOME_DIR=${BARCELONA_HOME:-$HOME/.bun-barcelona}
BIN_DIR=${BARCELONA_BIN-$HOME/.local/bin} # '' = install without a PATH symlink
ASSET=bun-barcelona-linux-x64.tar.gz
DRY=${BARCELONA_DRY:-0}
say() { printf '  %s\n' "$*"; }   # always on: installers should say what they did

api() { curl -fsSL -H 'Accept: application/vnd.github+json' "https://api.github.com$1"; }

# --- resolve target release -------------------------------------------------
# Releases are polled, not read from /releases/latest: GitHub orders that by its
# own semver heuristic, which mixes in prereleases and drafts. Newest *stable*
# v*-barcelona by numeric tag sort is deterministic and matches the publisher.
tag=${BARCELONA_TAG:-}
if [ -z "$tag" ]; then
  tag=$(api "/repos/$REPO/releases?per_page=100" \
    | tr ',{}' '\n\n\n' | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-barcelona$' | sort -V | tail -1) || true
fi
[ -n "$tag" ] || { printf 'error: no v*-barcelona release on %s\n' "$REPO" >&2; exit 1; }
ver=${tag#v}; ver=${ver%-barcelona}

say "release : $REPO  $tag  (bun $ver)"
[ "$DRY" = 1 ] && exit 0

# --- fetch + verify + place --------------------------------------------------
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT INT TERM
say "downloading $ASSET"
curl -fsSL --retry 3 -o "$tmp/$ASSET" "https://github.com/$REPO/releases/download/$tag/$ASSET"
( cd "$tmp" && tar xzf "$ASSET" )

# Unpacking onto a live binary can race a running bun; stage then move.
mkdir -p "$HOME_DIR"
for f in bun bun-barcelona lib; do
  [ -e "$tmp/$f" ] || { printf 'error: %s missing from the tarball\n' "$f" >&2; exit 1; }
  if [ -d "$tmp/$f" ]; then
    mkdir -p "$HOME_DIR/$f"; cp -f "$tmp/$f/"* "$HOME_DIR/$f/"
  else
    cp -f "$tmp/$f" "$HOME_DIR/$f.new"; mv -f "$HOME_DIR/$f.new" "$HOME_DIR/$f"
  fi
done
chmod +x "$HOME_DIR/bun" "$HOME_DIR/bun-barcelona" 2>/dev/null || true

# The wrapper sets LD_LIBRARY_PATH for the bundled ICU; call it, never the ELF.
[ -n "$BIN_DIR" ] && { mkdir -p "$BIN_DIR"; ln -sf "$HOME_DIR/bun" "$BIN_DIR/bun"; say "on PATH: $BIN_DIR/bun"; }

say "version : $("$HOME_DIR/bun" --version)"
say "smoke   : $("$HOME_DIR/bun" -e 'console.log([...new Int32Array([5,3,8,1,9]).sort()].join(""))')"
say "bun $ver (barcelona) installed to $HOME_DIR"
