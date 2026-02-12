{
  lib,
  makeWrapper,
  runCommand,
  bash,
  coreutils,
}:

let
  src = ./openrouter-credits.sh;
  binName = "openrouter-credits";

  deps = [
    bash
    coreutils
  ];
in
runCommand "${binName}"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Prints remaining credits for openrouter";
      platforms = lib.platforms.unix;
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}

    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
