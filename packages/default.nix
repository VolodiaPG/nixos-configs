# ponytail: single listing for in-repo packages, evaluated per-system by default.nix.
{
  pkgs,
  inputs,
  system,
}:
{
  theme-switcher = pkgs.callPackage ./theme-switcher/default.nix {
    # thunk: on darwin stdenv.isLinux is false so linuxDeps (which uses noctalia) is never forced
    noctalia = inputs.noctalia.packages.${system}.default or null;
  };
  tmux-session-color = pkgs.callPackage ./tmux-session-color/default.nix { };
  openrouter-credits = pkgs.callPackage ./openrouter-credits/default.nix { };
  xinstall = pkgs.callPackage ./xinstall/default.nix { };
  xmount = pkgs.callPackage ./xmount/default.nix { };
  mpv-rife = pkgs.callPackage ./mpv-rife/default.nix { };
}
