# Yandex Music Nix Package

Standalone Nix flake for packaging the official Yandex Music Linux `.deb`.

```bash
nix build .#yandex-music
nix run .
```

This package tracks the current official Yandex Music Debian package published
by Yandex.

Detailed docs:

- [Architecture](docs/architecture.md)
- [Maintenance](docs/maintenance.md)

## Updating

Update to a specific Yandex Music version:

```bash
nix run .#update -- 5.96.0
```

The update app updates `ym_info.json` with the official `.deb` URL and Nix
hash, then formats the Nix files. After updating, verify the package:

```bash
nix build .#yandex-music --no-link
```

The update app is built with `writeShellApplication`, so it does not require Nix
channels or `NIX_PATH`.

If this project is used as a local flake input elsewhere, refresh that lock
file after the package build passes.

The flake also exposes:

- `packages.x86_64-linux.yandex-music`
- `packages.x86_64-linux.default`
- `apps.x86_64-linux.default`
- `apps.x86_64-linux.update`
- `overlays.default`
- `homeManagerModules.default`
