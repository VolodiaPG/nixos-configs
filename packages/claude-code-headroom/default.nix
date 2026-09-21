# claude-code wrapped to route its Anthropic traffic through a local headroom
# proxy, so every tool result and file read is compressed before it reaches the
# model. Drop-in: the wrapper is itself called `claude`, takes the same
# arguments, and writes nothing to stdout of its own — which is what lets
# non-interactive callers (the T3 Code app, `claude -p`, the SDK) parse the
# stream they expect.
#
# `headroom wrap claude` is the upstream equivalent, but it prints a launch
# banner and rewrites .claude/settings.local.json in the project it runs from.
# This wrapper instead does the two things that actually matter — make sure the
# proxy is up, then hand Claude Code the env pointing at it — and leaves the
# repo alone.
{
  lib,
  writeShellApplication,
  claude-code,
  headroom,
  coreutils,
}:
writeShellApplication {
  name = "claude";

  runtimeInputs = [
    claude-code
    headroom
    coreutils
  ];

  # `claude` must resolve to the real binary, not to this wrapper, both for the
  # exec below and for `headroom`'s own shutil.which("claude") lookups.
  text = ''
    port="''${HEADROOM_PORT:-8787}"
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/headroom"

    # TCP probe, same liveness test headroom's own `wrap` uses.
    proxy_up() {
      (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null
    }

    if ! proxy_up; then
      mkdir -p "$log_dir"
      HEADROOM_AGENT_TYPE=claude \
        nohup headroom proxy --port "$port" >>"$log_dir/proxy.log" 2>&1 &
      disown || true

      # Bounded wait for the bind. The very first start also downloads the
      # compression model from HuggingFace into ~/.cache, which is why the
      # budget is minutes rather than seconds; later starts take ~2s.
      echo "claude: starting headroom proxy on port $port..." >&2
      for _ in $(seq 1 360); do
        proxy_up && break
        sleep 0.5
      done

      if ! proxy_up; then
        echo "claude: headroom proxy failed to start on port $port," \
             "see $log_dir/proxy.log — falling back to a direct connection" >&2
        exec ${lib.getExe claude-code} "$@"
      fi
    fi

    export ANTHROPIC_BASE_URL="http://127.0.0.1:$port"
    # A custom ANTHROPIC_BASE_URL otherwise makes Claude Code materialize every
    # MCP/system tool schema into context (headroom GH #746); keep deferral on.
    export ENABLE_TOOL_SEARCH="''${ENABLE_TOOL_SEARCH:-true}"

    exec ${lib.getExe claude-code} "$@"
  '';

  meta = {
    description = "Claude Code routed through a local headroom compression proxy";
    inherit (claude-code.meta) homepage platforms;
    mainProgram = "claude";
  };
}
