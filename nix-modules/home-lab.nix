{
  pkgs,
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
      enable = true;
      environmentFile = config.age.secrets.tailscale-authkey.path;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/tailscale/caddy-tailscale@v0.0.0-20251117033914-662ef34c64b1"
        ];
        hash = "sha256-LZPejlDq/ak5w/h9V3ic8XFpj4QU4ce/3dLA1w8RAD0=";
      };
      globalConfig = ''
        servers {
            protocols h1 h2
        }
      '';
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
