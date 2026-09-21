# Claude Code, installed from nixpkgs rather than by its own npm installer, and
# by default pointed at a local headroom proxy so tool output and file reads are
# compressed before they reach the model.
#
# The installed binary is called `claude` either way, so anything that just
# execs `claude` — a shell, the T3 Code app's `binaryPath` — picks up the
# headroom routing without knowing about it.
#
# rtk and codegraph are different in kind from headroom: headroom is routed in
# by an env var the wrapper sets per-launch, but rtk and codegraph hook into
# Claude Code itself — a PreToolUse hook in `~/.claude/settings.json` (rtk) and
# an MCP server entry in `~/.claude.json` (codegraph). Both files are also
# written to by Claude Code at runtime (theme, onboarding, OAuth state), so
# Home Manager can't own them outright; instead their own idempotent
# installers merge the one block each needs, run once per activation.
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

      rtk.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Install rtk's PreToolUse hook, which rewrites Bash tool calls (e.g.
          `git status` -> `rtk git status`) to shrink their output before it
          reaches the model. Only covers the Bash tool — Read/Grep/Glob are
          untouched.
        '';
      };

      codegraph.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Register codegraph's MCP server with Claude Code, giving it a
          pre-built symbol/call-graph index instead of grep-and-read
          discovery. Per-project indexing still needs `codegraph init`,
          run once inside each repo.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      # claude-code and claude-code-headroom both install a `bin/claude`, so
      # exactly one of them may be in the profile at a time.
      packages = [
        (if cfg.headroom.enable then pkgs.claude-code-headroom else pkgs.claude-code)
        pkgs.t3code
      ]
      ++
        lib.optional cfg.headroom.enable
          # The CLI itself, for `headroom stats`, `headroom doctor`, and the
          # dashboard — and because the wrapper needs it on PATH anyway.
          pkgs.headroom
      ++ lib.optional cfg.rtk.enable pkgs.rtk
      ++ lib.optional cfg.codegraph.enable pkgs.codegraph;

      sessionVariables = mkIf cfg.headroom.enable {
        HEADROOM_PORT = toString cfg.headroom.port;
      };

      # Runs after Home Manager has linked packages into $NIX_PROFILES/bin, so
      # `rtk`/`codegraph` on $PATH below actually resolve.
      activation = mkIf (cfg.rtk.enable || cfg.codegraph.enable) {
        claudeAgentTools = lib.hm.dag.entryAfter [ "installPackages" ] ''
          PATH="${config.home.path}/bin:$PATH"

          ${lib.optionalString cfg.rtk.enable ''
            # --auto-patch: approve overwriting a stock hook block without
            # prompting, but never touch unrelated content — safe to re-run.
            RTK_TELEMETRY_DISABLED=1 run ${pkgs.rtk}/bin/rtk init -g --auto-patch
          ''}
          ${lib.optionalString cfg.codegraph.enable ''
            # --target=claude: wire up Claude Code only, not every agent
            # codegraph can detect on this machine.
            CODEGRAPH_TELEMETRY=0 run ${pkgs.codegraph}/bin/codegraph install --yes --target=claude
          ''}
        '';
      };
    };
  };
}
