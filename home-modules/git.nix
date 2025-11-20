{
  user,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        inherit (user) name email;
      };
      rebase.autostash = true;
      init.defaultBranch = "main";
      core.editor = "nvim";
      alias.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
    signing = {
      format = "ssh";
      key = user.signingKey;
      signByDefault = true;
    };
  };
}
