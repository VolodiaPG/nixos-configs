{
  common-home = import ./common-home.nix;
  git = import ./git.nix;
  zsh = import ./zsh.nix;
  ssh = import ./ssh.nix;
  syncthing = import ./syncthing.nix;
  gnome = import ./gnome.nix;
  mail = import ./mail.nix;
  mpv = import ./packages/mpv.nix;
  packages-personal = import ./packages-personal.nix;
}
