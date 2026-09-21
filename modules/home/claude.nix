# Claude Code, installed from nixpkgs rather than by its own npm installer, and
# by default pointed at a local headroom proxy so tool output and file reads are
# compressed before they reach the model.
#
# The installed binary is called `claude` either way, so anything that just
# execs `claude` — a shell, the T3 Code app's `binaryPath` — picks up the
# headroom routing without knowing about it.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.claude;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options = {
    my.claude = {
      enable = mkEnableOption "Claude Code";

      headroom = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Route Claude Code through a local headroom compression proxy. The
            proxy is started on first use and stays up for later sessions.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 8787;
          description = "Loopback port the headroom proxy listens on.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      # Both packages install a `bin/claude`, so exactly one of them may be in
      # the profile at a time.
      packages =
        if cfg.headroom.enable then
          [
            pkgs.claude-code-headroom
            # The CLI itself, for `headroom stats`, `headroom doctor`, and the
            # dashboard — and because the wrapper needs it on PATH anyway.
            pkgs.headroom
          ]
        else
          [ pkgs.claude-code ];

      sessionVariables = mkIf cfg.headroom.enable {
        HEADROOM_PORT = toString cfg.headroom.port;
      };
    };
  };
}
