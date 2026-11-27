#!/usr/bin/env bash
set -euo pipefail

mode="$1"
version="$2"
[[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || { echo "Invalid version" >&2; exit 1; }
tag="v$version"

if [[ "$mode" == retry ]]; then
  if git show-ref --verify --quiet "refs/tags/$tag"; then
    commit="$(git rev-parse "refs/tags/$tag^{commit}")"
    git merge-base --is-ancestor "$commit" HEAD
    [[ "$(git show "$commit:ym_info.json" | jq -r .version)" == "$version" ]] || {
      echo "Tag $tag has incorrect package version" >&2; exit 1;
    }
    echo "tag_exists=true" >> "$GITHUB_OUTPUT"
    releases="$(gh api --paginate 'repos/{owner}/{repo}/releases?per_page=100')"
    jq -s -e 'all(.[]; type == "array") and length > 0' <<< "$releases" > /dev/null
    published="$(jq -s -r --arg tag "$tag" 'any(.[][]; .tag_name == $tag and .draft == false)' <<< "$releases")"
    if [[ "$published" == false ]]; then
      echo "tag=$tag" >> "$GITHUB_OUTPUT"
      echo "commit=$commit" >> "$GITHUB_OUTPUT"
    fi
  fi
  exit 0
fi
[[ "$mode" == update ]] || { echo "Invalid mode" >&2; exit 1; }
[[ "$(jq -r .version ym_info.json)" == "$version" ]] || { echo "Packaged version mismatch" >&2; exit 1; }
if ! git diff --quiet || ! git diff --cached --quiet; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add ym_info.json package.nix default.nix flake.nix
  git commit -m "Update Yandex Music to $version"
fi
commit="$(git rev-parse HEAD)"
make check
[[ "$(git rev-parse HEAD)" == "$commit" ]] && git diff --quiet && git diff --cached --quiet || {
  echo "Checked commit changed during build" >&2; exit 1;
}
# Never reuse a tag for an update, even when it is an ancestor.
git -c tag.gpgSign=false tag "$tag" "$commit"
git push --atomic origin "$commit:refs/heads/master" "refs/tags/$tag:refs/tags/$tag"
echo "tag=$tag" >> "$GITHUB_OUTPUT"
echo "commit=$commit" >> "$GITHUB_OUTPUT"
