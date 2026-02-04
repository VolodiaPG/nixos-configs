{
  lib,
  stdenv,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  coreutils,
  kitty,
  tmux,
  lazygit,
  neovim-remote,
  ripgrep,
  # Linux-specific
  glib,
}:

let
  src = ./theme-switcher.sh;
  binName = "theme-switcher";

  # Base dependencies available on all platforms
  baseDeps = [
    bash
    coreutils
    kitty
    tmux
    lazygit
    neovim-remote
    ripgrep
  ];

  # Linux-specific dependencies (gsettings for theme detection)
  linuxDeps = lib.optionals stdenv.isLinux [
    glib # provides gsettings
  ];

  # Darwin uses `defaults` which is built into macOS, no extra packages needed
  deps = baseDeps ++ linuxDeps;
in
runCommand "${binName}"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Catppuccin theme switcher for kitty, tmux, lazygit, and neovim";
      platforms = lib.platforms.unix;
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}

    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
