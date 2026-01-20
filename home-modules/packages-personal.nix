{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # Because Opencode is special and doesn't support readonly config
  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cat <<EOF  > ~/.config/opencode/opencode.json
    {
      "plugin": ["@plannotator/opencode@latest"]
    }
    EOF
  '';
  home.packages = [
    pkgs.cachix
    pkgs.nvim
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    # pkgs.devenv
    (pkgs.devenv.overrideAttrs (_old: {
      postInstall =
        let
          setDefaultLocaleArchive = lib.optionalString (pkgs.glibcLocalesUtf8 != null) ''
            --set-default LOCALE_ARCHIVE ${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive
          '';
        in
        ''
          wrapProgram $out/bin/devenv \
            --prefix PATH ":" "$out/bin:${pkgs.cachix}/bin" \
            --set DEVENV_NIX ${pkgs.nix}/bin/nix \
            ${setDefaultLocaleArchive}

          # Generate manpages
          cargo xtask generate-manpages --out-dir man
          installManPage man/*

          # Generate shell completions
          compdir=./completions
          for shell in bash fish zsh; do
            cargo xtask generate-shell-completion $shell --out-dir $compdir
          done

          installShellCompletion --cmd devenv \
            --bash $compdir/devenv.bash \
            --fish $compdir/devenv.fish \
            --zsh $compdir/_devenv
        '';
    }))
  ];
}
