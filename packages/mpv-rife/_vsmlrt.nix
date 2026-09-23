{
  lib,
  buildPythonPackage,
  python,
  fetchurl,
  p7zip,
  symlinkJoin,
  vapoursynth,
  tensorrt,
  vstrt,
  miscfilters,
  src,
  version,
}:
let
  # rife.py loads both vstrt (core.trt) and miscfilters (core.misc) by walking
  # this same directory, so join them once instead of tracking two paths.
  plugins = symlinkJoin {
    name = "vsmlrt-plugins";
    paths = [
      vstrt
      miscfilters
    ];
  };

  # ponytail: vs-mlrt ships models outside the source tree. The per-model
  # archives in the external-models release each contain rife/<model>.onnx
  # (implementation 1, needs frame dims divisible by 32/64) and
  # rife_v2/<model>.onnx (implementation 2, pads internally — the only one
  # usable at arbitrary resolutions, see _implementation=2 in the mpv scripts).
  fetchRifeModel =
    { model, hash }:
    fetchurl {
      name = "vsmlrt-model-${model}";
      url = "https://github.com/AmusementClub/vs-mlrt/releases/download/external-models/${model}.7z";
      inherit hash;
      downloadToTemp = true;
      recursiveHash = true;
      nativeBuildInputs = [ p7zip ];
      postFetch = ''
        mkdir -p "$out"
        7z x -o"$out" "$downloadedFile" > /dev/null
      '';
    };

  models = symlinkJoin {
    name = "vsmlrt-rife-models";
    paths = [
      (fetchRifeModel {
        model = "rife_v4.25";
        hash = "sha256-d6MWNsvmUQzXujU2ZIxblVifAc6DneEvQahrq8kyGsU=";
      })
      (fetchRifeModel {
        model = "rife_v4.7";
        hash = "sha256-cZwmXKTFC7JHkHG0FFNesEAf4OmCqSEL5SxJLDKcG60=";
      })
      (fetchRifeModel {
        model = "rife_v4.25_lite";
        hash = "sha256-dZSfkmZUhRMceT8IBu4CnHfB0sl3zAzlcvR8GK6A59Y=";
      })
    ];
  };

  # ponytail: upstream derives every path from wherever VapourSynth autoloaded
  # the plugin from. Nothing autoloads here, so load vstrt and miscfilters by
  # store path on import and pin the model/trtexec paths to their own store
  # paths.
  loadPlugin = ''
    if not hasattr(core, "trt"):
        core.std.LoadPlugin(path="${plugins}/lib/vapoursynth/libvstrt.so")
    if not hasattr(core, "misc"):
        core.std.LoadPlugin(path="${plugins}/lib/vapoursynth/libmiscfilters.so")

    plugins_path: str = "${plugins}/lib/vapoursynth"'';
in
buildPythonPackage {
  pname = "vsmlrt";
  inherit version src;

  format = "other";

  postPatch = ''
    substituteInPlace scripts/vsmlrt.py \
      --replace-fail 'plugins_path: str = get_plugins_path()' ${lib.escapeShellArg loadPlugin} \
      --replace-fail \
        'trtexec_path: str = os.path.join(plugins_path, "vsmlrt-cuda", "trtexec")' \
        'trtexec_path: str = "${lib.getBin tensorrt}/bin/trtexec"' \
      --replace-fail \
        'models_path: str = os.path.join(plugins_path, "models")' \
        'models_path: str = "${models}"'
  '';

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm644 scripts/vsmlrt.py "$out/${python.sitePackages}/vsmlrt.py"
    runHook postInstall
  '';

  dependencies = [ vapoursynth ];

  # Importing it builds a CUDA context, so it cannot run in the sandbox.
  # pythonImportsCheck = [ "vsmlrt" ];

  meta = {
    description = "Python interface to the vs-mlrt VapourSynth filters";
    homepage = "https://github.com/AmusementClub/vs-mlrt";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
