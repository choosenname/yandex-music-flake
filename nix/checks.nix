{
  pkgs,
  bash,
  jq,
  packageFile,
  defaultFile,
  flakeFile,
  ymInfoFile,
  updateScript,
}:

{
  package-structure = pkgs.runCommand "yandex-music-package-structure" { } ''
    grep -q 'ym_info.json' ${packageFile}
    grep -q 'version = ymInfo.version;' ${packageFile}
    grep -q 'Yandex_Music_amd64_.*\.deb' ${ymInfoFile}
    grep -q 'data.tar.xz' ${packageFile}
    grep -q 'makeWrapper' ${packageFile}
    grep -q 'passthru.updateScript = ./scripts/update-yandex-music.sh;' ${packageFile}
    grep -q 'writeShellApplication' ${./update-app.nix}
    grep -q 'apps = forAllSystems' ${flakeFile}
    grep -q 'overlays.default' ${flakeFile}
    test -f ${defaultFile}
    test -f ${updateScript}
    touch "$out"
  '';

  update-script = pkgs.runCommand "yandex-music-update-script-tests" { } ''
    set -euo pipefail

    script=${updateScript}

    set +e
    ${bash}/bin/bash "$script" 2>usage.err
    status=$?
    set -e
    test "$status" -eq 2
    grep -q 'Usage: update-yandex-music <yandex-music-version>' usage.err

    empty_dir="$(mktemp -d)"
    set +e
    (cd "$empty_dir" && ${bash}/bin/bash "$script" 1.2.3) 2>wrong-dir.err
    status=$?
    set -e
    test "$status" -eq 2
    grep -q 'Run this from the yandex-music-flake project root.' wrong-dir.err

    project_dir="$(mktemp -d)"
    cp ${packageFile} "$project_dir/package.nix"
    cp ${defaultFile} "$project_dir/default.nix"
    cp ${flakeFile} "$project_dir/flake.nix"
    cp ${ymInfoFile} "$project_dir/ym_info.json"
    chmod u+w "$project_dir/ym_info.json" "$project_dir/package.nix" "$project_dir/default.nix" "$project_dir/flake.nix"

    mock_bin="$(mktemp -d)"
    cat > "$mock_bin/nix" <<'EOF'
    #!${bash}/bin/bash
    set -euo pipefail
    if [ "$#" -eq 4 ] \
      && [ "$1" = "store" ] \
      && [ "$2" = "prefetch-file" ] \
      && [ "$3" = "--json" ]; then
      printf '%s\n' '{"hash":"sha256-testhash"}'
      printf '%s\n' "$4" > "$TMPDIR/prefetched-url"
      exit 0
    fi
    echo "unexpected nix invocation: $*" >&2
    exit 1
    EOF
    chmod +x "$mock_bin/nix"

    cat > "$mock_bin/nixfmt" <<'EOF'
    #!${bash}/bin/bash
    set -euo pipefail
    printf '%s\n' "$*" > "$TMPDIR/nixfmt-args"
    EOF
    chmod +x "$mock_bin/nixfmt"

    (
      cd "$project_dir"
      PATH="$mock_bin:${jq}/bin:$PATH" ${bash}/bin/bash "$script" 6.7.8
    )

    ${jq}/bin/jq -e \
      '.version == "6.7.8"
        and .deb_name == "Yandex_Music_amd64_6.7.8.deb"
        and .deb_link == "https://desktop.app.music.yandex.net/stable/Yandex_Music_amd64_6.7.8.deb"
        and .deb_hash == "sha256-testhash"' \
      "$project_dir/ym_info.json"

    grep -q 'Yandex_Music_amd64_6.7.8.deb' "$TMPDIR/prefetched-url"
    grep -q 'package.nix default.nix flake.nix' "$TMPDIR/nixfmt-args"

    touch "$out"
  '';
}
