{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = with pkgs; [
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
    zotero

    # Media
    tidal-hifi
    libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
    # mpv
    vlc

    # Chat
    discord

    # Development
    insomnia

    signal-desktop
    (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
    popcorntime
    qbittorrent
  ];

  # programs.steam.enable = true;
}
