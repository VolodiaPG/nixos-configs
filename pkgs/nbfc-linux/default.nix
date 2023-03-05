{
  stdenv,
  fetchFromGitHub,
  pkgs,
  lib,
  ...
}:
stdenv.mkDerivation rec {
  pname = "nbfc-linux";
  version = "c6abef1b9f4ec4bb8a2eb4d7e70c1fccbb320677";
  src =
    pkgs.fetchFromGitHub
    {
      owner = pname;
      repo = pname;
      rev = version;
      sha256 = "sha256-qklVL7qFzyiIIm00AKRLE+uCYppTQ/S5C6exg0j2fSY=";
    };

  postInstall = ''
    ln -s ${./AsusUX430UAVolodia.json} "$out/share/nbfc/configs/Asus UX430UA Volodia.json"
  '';

  makeFlags = ["PREFIX=${placeholder "out"}"];

  meta = with lib; {
    description = "NoteBook FanControl ported to Linux (with Lan Tian's modifications)";
    homepage = "https://github.com/nbfc-linux/nbfc-linux";
    license = licenses.gpl3;
  };
}
