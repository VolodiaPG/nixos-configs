{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Terminal tools
    coreutils # Basic GNU utilities
    gitAndTools.gitFull # Git core installation
    gnupg # GNU Privacy Guard
  ];
}
