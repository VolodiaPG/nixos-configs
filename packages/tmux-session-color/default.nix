{
  lib,
  makeWrapper,
  runCommand,
  bash,
  coreutils,
}:

let
  src = ./tmux-session-color.sh;
  binName = "tmux-session-color";

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
      description = "Generate catppuccin colors for tmux sessions based on session name";
      platforms = lib.platforms.unix;
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}

    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
