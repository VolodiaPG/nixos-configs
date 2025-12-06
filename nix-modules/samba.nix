{
  pkgs,
  config,
  user,
  ...
}:
let
  mount =
    { path }:
    {
      browseable = "yes";
      comment = "Share for ${path}.";
      "guest ok" = "no";
      inherit path;
      "read only" = "yes";
    };
in
{
  services.samba = {
    enable = true;
    package = pkgs.samba;
    openFirewall = true;

    # https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "hosts allow" = "192.168.1. 100. 127.0.0.1 localhost"; # localhost = ::1
        "hosts deny" = "0.0.0.0/0";
        "invalid users" = [
          "root"
        ];
        "passwd program" = "/run/wrappers/bin/passwd %u";
        security = "user";
      };

      movies = mount { path = "/data/media/torrents/radarr"; };
      series = mount { path = "/data/media/torrents/sonarr"; };
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish.enable = true;
      publish.userServices = true; # auto register mDNS records
    };

    # Enable autodiscovery on Windows
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      discovery = true;
    };
  };

  systemd.services.samba-user-setup = {
    description = "Setup Samba user";
    wantedBy = [ "multi-user.target" ];
    before = [ "samba-smbd.service" ];
    requiredBy = [ "samba-smbd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${pkgs.samba}/bin/pdbedit -L | grep -q '^${user.username}:'; then
        passwd="$(cat ${config.age.secrets.samba-user-password.path})";
        (echo "$$passwd"; echo "$$passwd") | ${pkgs.samba}/bin/smbpasswd -s -a ${user.username}
      fi
    '';
  };

}
