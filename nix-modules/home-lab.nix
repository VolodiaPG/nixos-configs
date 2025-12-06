{
  config,
  user,
  ...
}:
{
  services = {
    home-assistant = {
      enable = true;
      config = null;
      configDir = "/persistent/home-lab/home-assistant";
      extraComponents = [
        "default_config"
        "zha"
        # "matter" # TODO uses insecure version of openssl
        "esphome" # HINT currently unused
      ];
      extraPackages =
        ps: with ps; [
          # HACS
          aiogithubapi
          # # OIDC
          # python-jose
          # aiofiles
          # jinja2
          # bcrypt
          # joserfc
        ];
    };
    freshrss = {
      enable = true;
      dataDir = "/persistent/home-lab/freshrss";
      virtualHost = "https://rss.${user.tailname}";
      baseUrl = "https://rss.${user.tailname}";
      # passwordFile = config.age.secrets.rss-password.path;
      authType = "http_auth";
      webserver = "caddy";
    };
    tsidp = {
      enable = true;
      environmentFile = config.age.secrets.tailscale-authkey.path;
    };

    #https://msfjarvis.dev/posts/creating-private-services-on-nixos-using-tailscale-and-caddy/
    caddy = {
      virtualHosts = {
        "https://home.${user.tailname}" = {
          extraConfig = ''
            # This will create a new node at home.$TAILNET_NAME.ts.net
            bind tailscale/home
            # Enables the Tailscale authentication provider
            # tailscale_auth
            # reverse_proxy / https://home.${user.tailname}/auth/oidc/redirect
          '';
        };
        "https://rss.${user.tailname}" = {
          extraConfig = ''
            bind tailscale/rss
            # tailscale_auth
          '';
        };
      };
    };
  };
}
