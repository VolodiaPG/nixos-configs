{
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.programs.git;
in
{
  config = mkIf cfg.enable {
    programs.git = {
      settings = {
        user = {
          inherit (flake.config.me) name email;
        };
        rebase.autostash = true;
        init.defaultBranch = "main";
        core.editor = "vim";
        alias.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        diff.external = "difft";
      };
      signing = {
        format = "ssh";
        key = flake.config.me.signingKey;
        signByDefault = true;
      };
    };
  };
}
