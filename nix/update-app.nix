{
  pkgs,
  updateScript,
}:

pkgs.writeShellApplication {
  name = "update-yandex-music";
  runtimeInputs = [
    pkgs.jq
    pkgs.nix
    pkgs.nixfmt
  ];
  text = builtins.readFile updateScript;
}
