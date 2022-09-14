{ stdenv
, fetchFromGitHub
, lib
, ...
} @ args:

stdenv.mkDerivation rec {
  pname = "nbfc-linux";
  version = "c6abef1b9f4ec4bb8a2eb4d7e70c1fccbb320677";
  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;
    sha256 = "sha256-jKuCBKUm32ulgH0+/be2s+CgeBqTww+4K3RETFFCCOc=";
  };

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = with lib; {
    description = "NoteBook FanControl ported to Linux (with Lan Tian's modifications)";
    homepage = "https://github.com/xddxdd/nbfc-linux";
    license = licenses.gpl3;
  };
}
