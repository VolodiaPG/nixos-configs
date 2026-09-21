# headroom — local context-compression proxy for coding agents.
#
# Upstream ships `headroom-ai` as a maturin project: a Python package plus a
# Rust extension module (`headroom._core`). Building that from source would mean
# vendoring ~530 crates, so this takes the published abi3 wheel instead — one
# per platform, all four of which upstream builds. The wheel is cp310-abi3, so
# it loads unchanged on whatever 3.1x interpreter nixpkgs currently defaults to.
#
# Only the `proxy` and `code` extras are wired up: together they are exactly
# what `headroom wrap claude` needs (local proxy + tree-sitter code memory).
# The heavier extras (`ml`, `voice`, `image`, `evals`) drag in torch and are
# deliberately left out.
{
  lib,
  stdenv,
  fetchurl,
  python3,
  python3Packages,
}:
let
  version = "0.37.0";

  # Filename fragment + hash of the wheel for each platform upstream publishes.
  wheels = {
    aarch64-darwin = {
      tag = "macosx_11_0_arm64";
      hash = "sha256-tDkvaKjQLXTGLBc0z1vzJ1EdzHJnjwFmn0TwYSlE1Zw=";
    };
    x86_64-darwin = {
      tag = "macosx_10_12_x86_64";
      hash = "sha256-2J/VhY5wGtpT0BhJ9zA52JH62E2es3D5UtVlgZYtnPg=";
    };
    aarch64-linux = {
      tag = "manylinux_2_28_aarch64";
      hash = "sha256-vDDTGmuTNhVdYrvdmfPC9sWh7TiCqHMOoM2O3kxA+hk=";
    };
    x86_64-linux = {
      tag = "manylinux_2_28_x86_64";
      hash = "sha256-Lvxc32gaEMX8eionGkcRecQJB0U3BF9oKxDk1ySXb0Y=";
    };
  };

  wheel =
    wheels.${stdenv.hostPlatform.system}
      or (throw "headroom: no upstream wheel for ${stdenv.hostPlatform.system}");

  deps = with python3Packages; [
    # base install
    tiktoken
    pydantic
    litellm
    click
    rich
    opentelemetry-api
    ast-grep-cli
    pyyaml
    tomlkit
    # [proxy]
    fastapi
    uvicorn
    orjson
    httpx
    h2 # httpx[http2]: the proxy opens its upstream connection with http2=True
    openai
    mcp
    magika
    zstandard
    websockets
    onnxruntime
    transformers
    watchdog
    sqlite-vec
    # [code]
    tree-sitter
    tree-sitter-language-pack
  ];
in
python3Packages.buildPythonApplication {
  pname = "headroom";
  inherit version;
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/cp310/h/headroom-ai/headroom_ai-${version}-cp310-abi3-${wheel.tag}.whl";
    inherit (wheel) hash;
  };

  dependencies = deps;

  # `headroom proxy` re-execs itself as `sys.executable -m headroom.cli` (macOS
  # malloc tuning), and `headroom wrap` starts the proxy the same way. Both lose
  # the sys.path nixpkgs bakes into the console script, so the child dies with
  # "No module named 'headroom'". Exporting that same path as PYTHONPATH — which
  # the children do inherit — is what makes the proxy start at all.
  makeWrapperArgs = [
    "--prefix"
    "PYTHONPATH"
    ":"
    "${placeholder "out"}/${python3.sitePackages}:${python3Packages.makePythonPath deps}"
  ];

  # The wheel is abi3 and carries no test suite, so a smoke import of both the
  # Python package and its compiled core is the useful check here.
  pythonImportsCheck = [
    "headroom"
    "headroom._core"
  ];

  meta = {
    description = "Context compression proxy that shrinks what coding agents send to the LLM";
    homepage = "https://github.com/headroomlabs-ai/headroom";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
    platforms = lib.attrNames wheels;
  };
}
