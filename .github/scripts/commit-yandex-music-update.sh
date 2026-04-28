#!/usr/bin/env bash

set -euo pipefail

version="$1"

if git diff --quiet; then
  echo "No changes to commit."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add ym_info.json package.nix default.nix flake.nix
git commit -m "Update Yandex Music to $version"
git push origin HEAD:master
