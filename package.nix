{
  fetchurl,
  stdenvNoCC,
  lib,
  binutils,
  makeWrapper,
}:

let
  ymInfo = builtins.fromJSON (builtins.readFile ./ym_info.json);
in
stdenvNoCC.mkDerivation rec {
  pname = "yandex-music";
  version = ymInfo.version;

  src = fetchurl {
    url = ymInfo.deb_link;
    hash = ymInfo.deb_hash;
  };

  nativeBuildInputs = [
    binutils
    makeWrapper
  ];

  passthru.updateScript = ./scripts/update-yandex-music.sh;

  unpackPhase = ''
    runHook preUnpack
    ar x "$src" data.tar.xz
    tar -xJf data.tar.xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r ./opt "$out/"
    mkdir -p "$out/share"
    cp -r ./usr/share/. "$out/share/"

    substituteInPlace "$out/share/applications/yandexmusic.desktop" \
      --replace-fail 'Exec="/opt/Яндекс Музыка/yandexmusic" %U' 'Exec=yandex-music %U'

    mkdir -p "$out/bin"
    makeWrapper "$out/opt/Яндекс Музыка/yandexmusic" "$out/bin/yandex-music"
    runHook postInstall
  '';

  meta = {
    description = "Yandex Music desktop client packaged from the official .deb";
    homepage = "https://music.yandex.ru/";
    downloadPage = "https://music.yandex.ru/download/";
    license = lib.licenses.unfree;
    mainProgram = "yandex-music";
    platforms = lib.platforms.linux;
  };
}
