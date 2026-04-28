#!/usr/bin/env bash

set -euo pipefail

current_version="$(sed -n 's/^[[:space:]]*"version": "\([^"]*\)".*/\1/p' ym_info.json | head -n 1)"
latest_version="$(
  curl -fsSL https://desktop.app.music.yandex.net/stable/latest-linux.yml \
    | sed -n 's/^version: //p' \
    | head -n 1
)"

if [ -z "$current_version" ] || [ -z "$latest_version" ]; then
  echo "Failed to resolve current or latest Yandex Music version." >&2
  exit 1
fi

echo "current-version=$current_version" >> "$GITHUB_OUTPUT"
echo "latest-version=$latest_version" >> "$GITHUB_OUTPUT"

if [ "$current_version" = "$latest_version" ]; then
  echo "update-needed=false" >> "$GITHUB_OUTPUT"
  echo "Yandex Music $current_version is already packaged."
else
  echo "update-needed=true" >> "$GITHUB_OUTPUT"
  echo "Yandex Music update available: $current_version -> $latest_version"
fi
