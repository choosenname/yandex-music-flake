# Architecture

This repository is a small Nix flake that packages the official Yandex Music
Linux Debian package.

## Files

- `flake.nix` wires flake outputs together.
- `package.nix` defines the `yandex-music` derivation.
- `ym_info.json` stores the current upstream `.deb` version, URL, and Nix hash.
- `scripts/update-yandex-music.sh` updates `ym_info.json` for a requested
  version.
- `nix/update-app.nix` builds the update command with `writeShellApplication`.
- `nix/checks.nix` defines flake checks for package structure and update script
  behavior.
- `default.nix` supports legacy `nix-build` usage.

## Package Flow

1. `package.nix` reads `ym_info.json`.
2. `fetchurl` downloads the official `.deb`.
3. The derivation extracts `data.tar.xz` from the Debian archive.
4. The package copies upstream `opt/` and `usr/share/` into `$out`.
5. The desktop file is patched to run `yandex-music`.
6. `makeWrapper` exposes `$out/bin/yandex-music`.

The package does not repack the Windows installer and does not use an archived
third-party repository.

## Flake Outputs

- `packages.x86_64-linux.yandex-music`
- `packages.x86_64-linux.default`
- `packages.x86_64-linux.update-yandex-music`
- `apps.x86_64-linux.default`
- `apps.x86_64-linux.yandex-music`
- `apps.x86_64-linux.update`
- `checks.x86_64-linux.package-structure`
- `checks.x86_64-linux.update-script`
- `overlays.default`
- `homeManagerModules.default`
