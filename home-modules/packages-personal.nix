{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    pkgs.nvim
    inputs.llm-agents.packages.${pkgs.system}.opencode
    pkgs.devenv
  ];
}
