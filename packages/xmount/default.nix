{
  lib,
  makeWrapper,
  runCommand,
  bash,
  coreutils,
  gum,
  disko,
  jq,
  git,
}:

let
  src = ./xmount.sh;
  binName = "xmount";

  deps = [
    bash
    coreutils
    gum
    disko
    git
    jq
  ];
in
runCommand "${binName}"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Mount partitions";
      platforms = lib.platforms.unix;
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}

    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
