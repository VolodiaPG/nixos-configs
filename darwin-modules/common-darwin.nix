{
  pkgs,
  user,
  ...
}:
{
  imports = [ ];

  nix = {
    enable = false; # Use determinate system
    settings = {
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    extraOptions = ''
      extra-platforms = x86_64-darwin
    '';
  };

  users.users."${user.username}" = {
    name = user.username;
    home = user.homeDirectory;
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    terminal-notifier

    yabai
    skhd
  ];

  # launchd.daemons.linux-builder.serviceConfig = {
  #   StandardOutPath = "/var/log/linux-builder.log";
  #   StandardErrorPath = "/var/log/linux-builder.log";
  # };

  system.activationScripts.extraActivation.text = ''
    /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
  '';

  services = {
    yabai = {
      enable = true;
      package = pkgs.yabai;
      enableScriptingAddition = true;
    };
    skhd = {
      enable = false;
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
