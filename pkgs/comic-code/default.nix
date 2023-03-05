{
  stdenv,
  lib,
}:
stdenv.mkDerivation rec {
  version = "1.0.0";
  name = "comic-code-${version}";

  src = ../../secrets/ComicCodeLigatures;

  installPhase = ''
    mkdir -p $out/share/fonts/opentype/comic-code
    install $src/* $out/share/fonts/opentype
  '';

  meta = with lib; {
    homepage = "https://github.com/tonsky/FiraCode";
    description = "Monospace font with programming ligatures";
    longDescription = ''
      Fira Code is a monospace font extending the Fira Mono font with
      a set of ligatures for common programming multi-character
      combinations.
    '';
    license = licenses.ofl;
    maintainers = [maintainers.rycee];
    platforms = platforms.all;
  };
}
