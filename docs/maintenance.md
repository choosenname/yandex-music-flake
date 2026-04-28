# Maintenance

## Updating Yandex Music

Run the update app from the repository root:

```bash
nix run .#update -- 5.97.3
```

The update app:

1. Builds the official Debian package URL from the requested version.
2. Runs `nix store prefetch-file --json` to fetch the `.deb` and calculate its
   Nix hash.
3. Rewrites `ym_info.json`.
4. Formats `package.nix`, `default.nix`, and `flake.nix`.

After updating, verify the package:

```bash
nix build .#yandex-music --no-link
nix build .#checks.x86_64-linux.update-script --no-link
nix flake check --no-build
```

If another flake uses this repository through a local `path:` input, refresh
that consumer's lock file after the package build passes.

## Tests

The tests are flake checks in `nix/checks.nix`.

`package-structure` checks that the project still packages the official `.deb`
and exposes the expected flake wiring.

`update-script` tests the update script without network access by mocking
`nix store prefetch-file`. It verifies usage errors, root-directory validation,
generated `ym_info.json`, and the `nixfmt` invocation.

## Common Failure Modes

- `Permission denied` while updating usually means the update app is writing in
  the wrong directory. Run it from the repository root.
- `file 'nixpkgs' was not found in the Nix search path` should not happen for
  this project because update tooling is a flake app, not a `nix-shell` shebang.
- A missing `.deb` version will fail during `nix store prefetch-file`; check
  that Yandex has published the requested version for Linux.
