#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: update-yandex-music <yandex-music-version>" >&2
  echo "Example: update-yandex-music 5.95.0" >&2
  exit 2
fi

if [ ! -f flake.nix ] || [ ! -f ym_info.json ] || [ ! -f package.nix ]; then
  echo "Run this from the yandex-music-flake project root." >&2
  exit 2
fi

version="$1"
deb_name="Yandex_Music_amd64_${version}.deb"
deb_link="https://desktop.app.music.yandex.net/stable/${deb_name}"
deb_hash="$(nix store prefetch-file --json "$deb_link" | jq -r '.hash')"

jq -n \
  --arg version "$version" \
  --arg deb_name "$deb_name" \
  --arg deb_link "$deb_link" \
  --arg deb_hash "$deb_hash" \
  '{
    version: $version,
    deb_name: $deb_name,
    deb_link: $deb_link,
    deb_hash: $deb_hash
  }' > ym_info.json

nixfmt package.nix default.nix flake.nix
