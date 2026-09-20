{
  lib,
  cudaPackages,
  cmake,
  ninja,
  git,
  symlinkJoin,
  autoAddDriverRunpath,
  vapoursynth,
  tensorrt,
  src,
  version,
}:
let
  inherit (cudaPackages) backendStdenv cuda_cudart cuda_nvcc;

  # ponytail: vstrt's CMakeLists wants one TENSORRT_HOME holding include/ and
  # lib/; nixpkgs splits tensorrt across outputs, so glue them back together.
  tensorrtHome = symlinkJoin {
    name = "tensorrt-home-${tensorrt.version}";
    paths = [
      (lib.getOutput "include" tensorrt)
      (lib.getLib tensorrt)
    ];
  };
in
backendStdenv.mkDerivation {
  pname = "vapoursynth-vstrt";
  inherit version src;

  sourceRoot = "${src.name}/vstrt";

  # ponytail: the tarball has no .git, and `git describe` only feeds the string
  # reported by core.trt.Version(); hand it the tag directly instead.
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'COMMAND ''${GIT_EXECUTABLE} describe --tags --long --always' \
        'COMMAND ''${CMAKE_COMMAND} -E echo v${version}'
  '';

  nativeBuildInputs = [
    cmake
    ninja
    git # only for find_package(Git REQUIRED)
    cuda_nvcc # sets CUDAToolkit_ROOT for find_package(CUDAToolkit)
    autoAddDriverRunpath # libcuda.so.1 comes from the running driver
  ];

  buildInputs = [
    cuda_cudart
    (lib.getLib tensorrt)
  ];

  cmakeFlags = [
    (lib.cmakeFeature "VAPOURSYNTH_INCLUDE_DIRECTORY" "${vapoursynth}/include/vapoursynth")
    (lib.cmakeFeature "TENSORRT_HOME" "${tensorrtHome}")
    # VapourSynth autoloads plugins from <prefix>/lib/vapoursynth.
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib/vapoursynth")
  ];

  meta = {
    description = "VapourSynth TensorRT filter from vs-mlrt";
    homepage = "https://github.com/AmusementClub/vs-mlrt";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
