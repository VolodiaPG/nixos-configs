{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages =
    (with pkgs; [
      direnv # Load environment variables when cd'ing into a directory
      findutils # GNU find/xargs commands
      man # Documentation for everything
      p7zip # 7zip archive tools
      lrzip # Advanced and storage efficient zip
      parallel # Much smarter xargs
      progress # View current progress of coreutils tools
      zip # ZIP file manipulation
      unzip
      gdu # Manager files and see sizes quickly
      micro # text editor
      zoxide # smart CD that remembers
      gh # Github PRs and stuff
      git-crypt
      cocogitto
      python3
      ecryptfs

      # System monitoring
      htop # Interactive TUI process viewer
      lm_sensors # Read hardware sensors
      nmap # Network scanning and more

      # File transfer
      sshfs-fuse # Mount remote filesystem over SSH with FUSE
      wget # Retrieve files from the web

      # Fish deps
      fzf # Required by jethrokuan/fzf.
      grc
      libnotify
      notify-desktop
      tmux

      bottom # call btm
      libgtop

      remmina
      cloudflare-warp
      veracrypt
      pavucontrol

      distrobox

      powerstat

      # firefox-beta-bin
      brave
      # chromium
      #ungoogled-chromium
      #firefox-bin
      # tor-browser-bundle-bin

      # lapce
      (pkgs-unstable.vscode-with-extensions.override {
        vscodeExtensions = with pkgs-unstable.vscode-extensions;
          [
            # vadimcn.vscode-lldb
            matklad.rust-analyzer
            jnoortheen.nix-ide
            # ms-python.python
            skellock.just
            arrterian.nix-env-selector
            eamodio.gitlens
            usernamehw.errorlens
          ]
          ++ pkgs-unstable.vscode-utils.extensionsFromVscodeMarketplace [
            {
              publisher = "vscode-icons-team";
              name = "vscode-icons";
              version = "12.0.1";
              sha256 = "sha256-zxKD+8PfuaBaNoxTP1IHwG+25v0hDkYBj4RPn7mSzzU=";
            }
            {
              publisher = "teabyii";
              name = "ayu";
              version = "1.0.5";
              sha256 = "sha256-+IFqgWliKr+qjBLmQlzF44XNbN7Br5a119v9WAnZOu4=";
            }
            {
              publisher = "iliazeus";
              name = "vscode-ansi";
              version = "1.1.2";
              sha256 = "sha256-sQfaykUy3bqL2QFicxR6fyZQtOXtL/BqV0dbAPMh+lA=";
            }
          ];
      })

      # Office
      libreoffice
      xournalpp
      zotero

      # Media
      tidal-hifi
      libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
      # mpv
      vlc

      # Chat
      discord
      signal-desktop

      # Development
      nixpkgs-fmt # Nix formatter
      insomnia
      gitui

      # Utils
      # boxes

      spice-vdagent # copy paste for vms

      (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
      popcorntime
      qbittorrent
    ])
    ++ (with pkgs-unstable; [
      bottles
      lapce
      powertop
    ]);

  # programs.steam.enable = true;
}
