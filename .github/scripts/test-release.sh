#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/release-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
git init -q --bare "$tmp/remote.git"
git init -q -b master "$tmp/work"
cd "$tmp/work"
git config user.name test
git config user.email test@example.com
git remote add origin "$tmp/remote.git"
printf '{"version":"1.0"}\n' > ym_info.json
touch package.nix default.nix flake.nix
git add . && git commit -qm initial && git push -q origin master
mkdir "$tmp/bin"
printf '#!/bin/sh\ngit rev-parse HEAD > "$CHECKED_SHA"\nexit "${CHECK_EXIT:-0}"\n' > "$tmp/bin/make"
printf '#!/bin/sh\n[ "${GH_FAIL:-0}" = 0 ] || exit 1\nprintf "%%s\\n" "$RELEASES"\n' > "$tmp/bin/gh"
chmod +x "$tmp/bin/make" "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GITHUB_OUTPUT="$tmp/output" CHECKED_SHA="$tmp/checked"
script="$root/.github/scripts/commit-yandex-music-update.sh"
printf '{"version":"2.0"}\n' > ym_info.json
if CHECK_EXIT=1 "$script" update 2.0; then echo 'check failure was ignored' >&2; exit 1; fi
[[ "$(git rev-parse HEAD)" != "$(git --git-dir="$tmp/remote.git" rev-parse master)" ]]
"$script" update 2.0
grep -qx 'tag=v2.0' "$GITHUB_OUTPUT"
[[ "$(git --git-dir="$tmp/remote.git" rev-parse master)" == "$(git --git-dir="$tmp/remote.git" rev-parse v2.0)" ]]
[[ "$(cat "$CHECKED_SHA")" == "$(git --git-dir="$tmp/remote.git" rev-parse v2.0)" ]]
grep -qx "commit=$(cat "$CHECKED_SHA")" "$GITHUB_OUTPUT"
: > "$GITHUB_OUTPUT"
export RELEASES='[]'
"$script" retry 2.0
grep -qx 'tag=v2.0' "$GITHUB_OUTPUT"
grep -qx "commit=$(cat "$CHECKED_SHA")" "$GITHUB_OUTPUT"
: > "$GITHUB_OUTPUT"
export RELEASES='[{"tag_name":"v2.0","draft":true}]'
"$script" retry 2.0
grep -qx 'tag=v2.0' "$GITHUB_OUTPUT"
: > "$GITHUB_OUTPUT"
export RELEASES='[]
[{"tag_name":"v2.0","draft":false}]'
"$script" retry 2.0
printf 'tag_exists=true\n' | cmp -s - "$GITHUB_OUTPUT"
if GH_FAIL=1 "$script" retry 2.0; then echo 'lookup failure was ignored' >&2; exit 1; fi
if RELEASES='not-json' "$script" retry 2.0; then echo 'invalid lookup response was ignored' >&2; exit 1; fi
printf '{"version":"3.0"}\n' > ym_info.json
# Simulate a conflicting remote-only tag: neither remote ref may change.
git -c tag.gpgSign=false --git-dir="$tmp/remote.git" tag v3.0 master
old="$(git --git-dir="$tmp/remote.git" rev-parse master)"
if "$script" update 3.0; then echo 'tag conflict was ignored' >&2; exit 1; fi
[[ "$(git --git-dir="$tmp/remote.git" rev-parse master)" == "$old" ]]
[[ "$(git --git-dir="$tmp/remote.git" rev-parse v3.0)" == "$old" ]]
echo 'release checks passed'
