{ autoPatchelfHook
, fetchurl
, gcc-unwrapped
, gsettings-desktop-schemas
, gtk3
, lib
, makeDesktopItem
, makeWrapper
, nwjs
, stdenv
, unzip
, udev
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "popcorntime";
  version = "0.4.9";

  src = fetchurl {
    url = "https://github.com/popcorn-official/popcorn-desktop/releases/download/v${version}/Popcorn-Time-${version}-linux64.zip";
    sha256 = "sha256-cbKL5bgweZD/yfi/8KS0L7Raha8PTHqIm4qSPFidjUc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    unzip
    wrapGAppsHook
  ];

  buildInputs = [
    gcc-unwrapped
    gsettings-desktop-schemas
    gtk3
    nwjs
    udev
  ];

  sourceRoot = ".";

  dontWrapGApps = true;
  dontUnpack = true;

  makeWrapperArgs = [
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ gcc-unwrapped.lib gtk3 udev ]}"
    "--prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}"
  ];

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    comment = meta.description;
    genericName = meta.description;
    type = "Application";
    desktopName = "Popcorn-Time";
    categories = [ "System" ];
  };

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out/share/applications $out/bin $out/opt/bin $out/share/icons/hicolor/scalable/apps/
    # we can't unzip it in $out/lib, because nw.js will start with
    # an empty screen. Therefore it will be unzipped in a non-typical
    # folder and symlinked.
    unzip -q $src -d $out/opt/popcorntime
    
    ln -s $out/opt/popcorntime/Popcorn-Time $out/bin/${pname}

    ln -s $out/opt/${pname}/src/app/images/icon.png $out/share/icons/hicolor/scalable/apps/${pname}.png
    ln -s ${desktopItem}/share/applications/* $out/share/applications
  '';

  # GSETTINGS_SCHEMAS_PATH is not set in installPhase
  preFixup = ''
    wrapProgram $out/bin/${pname} \
      ''${makeWrapperArgs[@]} \
      ''${gappsWrapperArgs[@]}
  '';

  meta = with lib; {
    homepage = "https://github.com/popcorn-official/popcorn-desktop";
    description = "An application that streams movies and TV shows from torrents";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
