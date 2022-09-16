# https://github.com/NixOS/nixpkgs/issues/64344#issuecomment-745739682
{ stdenv
, lib
, fetchurl
, addOpenGLRunpath
, ocl-icd
, p7zip
, patchelf
, ...
}:
stdenv.mkDerivation rec {
  name = "svpflow-${version}";
  version = "4.5.210";

  src = fetchurl {
    url = "https://www.svp-team.com/files/svp4-linux.${version}-1.tar.bz2";
    sha256 = "10q8r401wg81vanwxd7v07qrh3w70gdhgv5vmvymai0flndm63cl";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    p7zip
    addOpenGLRunpath
  ];

  unpackPhase = ''
    tar xf ${src}
  
    mkdir installer
    LANG=C grep --only-matching --byte-offset --binary --text  $'7z\xBC\xAF\x27\x1C' "svp4-linux-64.run" |
      cut -f1 -d: |
      while read ofs; do dd if="svp4-linux-64.run" bs=1M iflag=skip_bytes status=none skip=$ofs of="installer/bin-$ofs.7z"; done

    for f in "installer/"*.7z; do
      7z -bd -bb0 -y x -o"./" "$f" || true
    done
  '';

  installPhase = ''
    mkdir -p $out/lib
    ls -lia
    cp plugins/libsvpflow{1,2}_vs64.so $out/lib/
  '';

  preFixup =
    let
      libPath = lib.makeLibraryPath [
        stdenv.cc.cc.lib
        ocl-icd
      ];
    in
    ''
      patchelf --shrink-rpath --add-needed ${ocl-icd}/lib/libOpenCL.so.1 --set-rpath "${libPath}" $out/lib/libsvpflow{1,2}_vs64.so
    '';

  postFixup = ''
    addOpenGLRunpath $out/lib/libsvpflow1_vs64.so
    addOpenGLRunpath $out/lib/libsvpflow2_vs64.so
  '';

  meta = with lib; {
    homepage = "https://svp-team.com/";
    description = "SmoothVideo Project - svpflow libraries";
    platforms = platforms.linux;
    maintainers = with maintainers; [ sinity ];
  };
}

