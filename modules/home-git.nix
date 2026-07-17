{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.base =
    {
      lib,
      config,
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
              inherit (me) name email;
            };
            rebase.autostash = true;
            init.defaultBranch = "main";
            core.editor = "vim";
            alias.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            diff.external = "difft";
          };
          signing = {
            format = "ssh";
            key = me.signingKey;
            signByDefault = true;
          };
        };
      };
    };
}
