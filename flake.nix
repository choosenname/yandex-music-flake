{
  description = "Nix package for the Yandex Music desktop client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      files = {
        defaultFile = ./default.nix;
        flakeFile = ./flake.nix;
        packageFile = ./package.nix;
        updateScript = ./scripts/update-yandex-music.sh;
        ymInfoFile = ./ym_info.json;
      };
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      overlays.default = final: _prev: {
        yandex-music = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        rec {
          yandex-music = pkgs.callPackage ./package.nix { };
          update-yandex-music = pkgs.callPackage ./nix/update-app.nix {
            inherit (files) updateScript;
          };
          default = yandex-music;
        }
      );

      apps = forAllSystems (system: {
        yandex-music = {
          type = "app";
          program = "${self.packages.${system}.yandex-music}/bin/yandex-music";
          meta.description = "Run the Yandex Music desktop client";
        };
        update = {
          type = "app";
          program = "${self.packages.${system}.update-yandex-music}/bin/update-yandex-music";
          meta.description = "Update the packaged Yandex Music version";
        };
        default = self.apps.${system}.yandex-music;
      });

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        import ./nix/checks.nix (
          files
          // {
            inherit pkgs;
            inherit (pkgs) bash jq;
          }
        )
      );

      homeManagerModules.default =
        { pkgs, ... }:
        {
          home.packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        };
    };
}
