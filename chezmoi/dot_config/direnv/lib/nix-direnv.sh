# shellcheck shell=bash
# direnv sources every ~/.config/direnv/lib/*.sh before an .envrc.
#
# Replaces Home Manager's lib/hm-nix-direnv.sh, which pointed at a /nix/store
# path. nix-direnv overrides direnv's built-in `use flake` with a cached
# version; roles/nix installs it into the Nix user profile. Guarded so that
# before roles/nix has run, `use flake` still works via direnv's own stdlib,
# just without the cache.
if [[ -f "$HOME/.nix-profile/share/nix-direnv/direnvrc" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.nix-profile/share/nix-direnv/direnvrc"
fi
