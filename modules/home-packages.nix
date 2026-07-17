{
  self,
  ...
}:
{
  config.home.base =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      home = {
        packages = with pkgs; [
          direnv
          findutils
          parallel
          zip
          unzip
          gdu
          zoxide
          git-crypt
          cocogitto
          python3
          htop
          nmap
          wget
          fzf
          grc
          libnotify
          notify-desktop
          tmux
          bottom
          libgtop
          # ponytail: play-with-mpv removed, depends on insecure youtube-dl
          mpv
        ];

        file = {
          ".config/mpv" = {
            source = "${self}/static/home/mpv";
            recursive = true;
          };
        };
      };
    };
}
