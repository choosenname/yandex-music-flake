.PHONY: check update

check:
	nix build .#yandex-music --no-link
	nix build .#checks.x86_64-linux.update-script --no-link
	nix flake check --no-build

update:
	@test -n "$(VERSION)" || (echo "Usage: make update VERSION=<yandex-music-version>" >&2; exit 2)
	nix run .#update -- "$(VERSION)"
