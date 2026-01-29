{
  pkgs,
  user,
  ...
}:
{
  imports = [ ];

  # nixpkgs.config = {
  #   allowUnfree = true;
  #   allowUnfreePredicate = _pkg: true;
  # };
  #
  # nix = {
  #   enable = true;
  #   package = pkgs.lixPackageSets.stable.lix;
  #   settings = {
  #     experimental-features = [
  #       "nix-command"
  #       "flakes"
  #     ];
  #
  #     allowed-users = [
  #       "root"
  #       "wheel"
  #       "@wheel"
  #       user.username
  #     ];
  #     trusted-users = [
  #       "root"
  #       user.username
  #     ];
  #   };
  #
  # };

  users.users."${user.username}" = {
    name = user.username;
    home = user.homeDirectory;
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    terminal-notifier
    kitty

    yabai
    skhd
  ];

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

  environment.shellInit = ''
    ulimit -n 524288
  '';

  launchd = {
    daemons = {
      # fixes "Too many open files" errors
      limit-maxfiles = {
        script = ''
          /bin/launchctl limit maxfiles 524288 524288
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = false;
          Label = "org.nixos.limit-maxfiles";
          StandardOutPath = "/var/log/limit-maxfiles.log";
          StandardErrorPath = "/var/log/limit-maxfiles.log";
        };
      };
    };
  };

  system = {
    defaults = {
      # Specifies the duration of a smooth frame-size change
      NSGlobalDomain.NSWindowResizeTime = 0.001;
    };

    activationScripts.extraActivation.text = ''
      /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
    '';
    stateVersion = 5;
  };
}
